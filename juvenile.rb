require 'rubygems'
require 'yaml'
require_relative "functions"

# open the config file
config = Functions.load_config
                  
#Loop through each app
config['apps'].each do |app, settings|
  Functions.upload(app, settings)
end