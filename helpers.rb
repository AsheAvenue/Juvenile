class Helpers
  
  def self.compute_part_size(options)
    max_parts = 1000
    min_size  = 5242880 #5 MB
    estimated_size = options[:estimated_content_length]
    [(estimated_size.to_f / max_parts).ceil, min_size].max.to_i
  end
  
  def self.print_and_flush(str)
    print str
    $stdout.flush
  end
  
  def self.output(log, log_type, str)
    if log_type == "info"
      log.info str
    elsif log_type == "error"
      log.error str
    end
    puts str
  end
  
end