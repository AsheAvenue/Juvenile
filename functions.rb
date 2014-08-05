require 'rubygems'
require 'aws/s3'
require 'yaml'

class Functions

  def self.load_config
    YAML::load(File.open(File.join(File.dirname(__FILE__), "config.yml")))  
  end
  
  def self.upload(app, settings)
    #Set variables based on the config
    db_type = settings['db']['type']
    db_host = settings['db']['host']
    db_name = settings['db']['database']
    db_username = settings['db']['username']
    db_password = settings['db']['password']
    s3_access_key_id = settings['s3']['access_key_id']
    s3_secret_access_key = settings['s3']['secret_access_key']
    s3_bucket = settings['s3']['bucket']
    s3_subdirectory = settings['s3']['subdirectory']
    number_of_days_to_keep = settings['number_of_days_to_keep']
    prefix = settings['prefix']

    if db_type == "mysql"
      #Run a mysqldump and save the file locally
      dump_name = "#{prefix}#{app}_#{Time.now.strftime("%Y%m%d%H%M")}.sql"
      command = "mysqldump -u#{db_username} -p#{db_password} -h#{db_host} --hex-blob #{db_name} > ./#{dump_name}"
      result = `#{command}`
    end

    #Tarball the file
    tarred_dump_name = "#{dump_name}.tar.gz"
    tar_command = "tar cvfj #{tarred_dump_name} #{dump_name}"
    result = `#{tar_command}`

    #Connect to S3
    s3 = AWS::S3.new(
      :access_key_id     => s3_access_key_id,
      :secret_access_key => s3_secret_access_key)
    bucket = s3.buckets[s3_bucket]

    #Get the objects in the bucket
    objects = bucket.objects.with_prefix("#{s3_subdirectory}/#{prefix}")

    #Prep the file to be uploaded
    file = File.open(File.join(File.dirname(__FILE__), tarred_dump_name), 'rb', encoding: 'BINARY')
    opts = { :estimated_content_length => file.size }
    part_size = Functions.compute_part_size(opts)

    #Do the upload
    new_obj = bucket.objects["#{s3_subdirectory}/#{tarred_dump_name}"]
    begin
      new_obj.multipart_upload(opts) do |upload|
        until file.eof? do
          break if (abort_upload = upload.aborted?)
          upload.add_part(file.read(part_size))
        end
      end
    end

    #Confirm the upload
    confirmed = bucket.objects["#{s3_subdirectory}/#{tarred_dump_name}"]
    if confirmed.exists?
      #Delete the old items in the bucket/subdirectory
      objects.delete_if {|obj|
        time_now = Time.new
        minutes_old = (time_now - obj.last_modified) / 60
        minutes_old > (number_of_days_to_keep * 24 * 60)
      }
    end

    #Delete the mysqldump file locally
    File.delete "#{dump_name}"
    File.delete "#{tarred_dump_name}"
  end
  

  def self.compute_part_size(options)
    max_parts = 1000
    min_size  = 5242880 #5 MB
    estimated_size = options[:estimated_content_length]
    [(estimated_size.to_f / max_parts).ceil, min_size].max.to_i
  end

end