require 'rubygems'
require 'aws/s3' #used for saving to s3
require 'yaml'
require 'logger'

require_relative "helpers"

# open the config file
config = YAML::load(File.open(File.join(File.dirname(__FILE__), "config.yml")))

#Set up logging
log = Logger.new(File.join(File.dirname(__FILE__), "output.log"))
log.level = Logger::INFO      

puts ""
puts "      #                                             "
puts "      # #    # #    # ###### #    # # #      ###### "
puts "      # #    # #    # #      ##   # # #      #      "
puts "      # #    # #    # #####  # #  # # #      #####  "
puts "#     # #    # #    # #      #  # # # #      #      "
puts "#     # #    #  #  #  #      #   ## # #      #      "
puts " #####   ####    ##   ###### #    # # ###### ###### "
puts ""
puts "A simple tool for managing database backups and making sandwiches"
puts ""
puts "(c) 2013 Ashe Avenue. Created by Tim Boisvert and Rob Farrell"
puts "Juvenile is released under the MIT license"
puts "http://github.com/AsheAvenue/Juvenile"
puts ""
puts "View output.log for backup results"

#track successes and errors
results = []
                                    
#Loop through each app
config['apps'].each do |app, settings|
  
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
  
  Helpers.output log, "info", ""
  Helpers.output log, "info",  "Backing up #{app}"
  
  if db_type == "mysql"
    #Run a mysqldump and save the file locally
    Helpers.output log, "info",  "- Running mysqldump"
    dump_name = "#{prefix}#{app}_#{Time.now.strftime("%Y%m%d%H%M")}.sql"
    command = "mysqldump -u#{db_username} -p#{db_password} -h#{db_host} --hex-blob #{db_name} > ./#{dump_name}"
    result = `#{command}`
  elsif db_type == "herokupg"
    
  end
  
  Helpers.output log, "info",  "- Dump saved locally: #{dump_name}"
  
  #Tarball the file
  tarred_dump_name = "#{dump_name}.tar.gz"
  tar_command = "tar cvfj #{tarred_dump_name} #{dump_name}"
  result = `#{tar_command}`
  Helpers.output log, "info",  "- Tarballed: #{tarred_dump_name}"
  
  #Connect to S3
  Helpers.output log, "info",  "- Connecting to S3"
  s3 = AWS::S3.new(
    :access_key_id     => s3_access_key_id,
    :secret_access_key => s3_secret_access_key)
  bucket = s3.buckets[s3_bucket]  
    
  #Get the objects in the bucket
  objects = bucket.objects.with_prefix("#{s3_subdirectory}/#{prefix}")
  Helpers.output log, "info",  "- Using subdirectory: #{bucket.name}/#{s3_subdirectory}"
  
  #Upload the mysqldump file
  Helpers.output log, "info",  "- Uploading #{tarred_dump_name} to S3"
  
  upload_progress = 0
  file = File.open(File.join(File.dirname(__FILE__), tarred_dump_name), 'rb', encoding: 'BINARY')
  opts = {
    estimated_content_length: file.size,
  }
  part_size = Helpers.compute_part_size(opts)
  
  new_obj = bucket.objects["#{s3_subdirectory}/#{tarred_dump_name}"]
  begin
    new_obj.multipart_upload(opts) do |upload|
      Helpers.print_and_flush "  "
      until file.eof? do
        break if (abort_upload = upload.aborted?)
        upload.add_part(file.read(part_size))
        Helpers.print_and_flush "#"
      end
      Helpers.output log, "info",  ""
    end
  end
  Helpers.output log, "info",  "- Finished uploading #{tarred_dump_name} to S3"
  
  #Confirm the upload
  Helpers.output log, "info",  "- Confirming upload"
  confirmed = bucket.objects["#{s3_subdirectory}/#{tarred_dump_name}"]
  if confirmed.exists?
    Helpers.output log, "info",  "- Upload confirmed"
    results << "Successfully backed up #{app}"
  
    #Delete the old items in the bucket/subdirectory
    Helpers.output log, "info",  "- Deleting old backups from S3"
    objects.delete_if {|obj| 
      time_now = Time.new
      minutes_old = (time_now - obj.last_modified) / 60
      minutes_old > (number_of_days_to_keep * 24 * 60)
    }
  else
    Helpers.output log, "error", "- #{tarred_dump_name} not found"
    results << "Error backing up #{app}"
  end

  #Delete the mysqldump file locally
  Helpers.output log, "info",  "- Deleting local files: #{dump_name}, #{tarred_dump_name}"
  File.delete "#{dump_name}"
  File.delete "#{tarred_dump_name}"

end

Helpers.output log, "info",  ""
Helpers.output log, "info",  "Results:"
results.each do |result|
  Helpers.output log, "info",  "- #{result}"
end