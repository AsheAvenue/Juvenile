require 'curb'
require 'json'
require_relative '../functions'

namespace :juvenile do
  desc "Perform a backup"
  task :backup, :app do |t, args|
    
    # Get the app
    app = args[:app]
    
    # Load the config
    config = Functions.load_config
    
    # if there is no app, or it's nil, run all tasks
    if !app || app == nil
      config['apps'].each do |app, settings|
        Functions.upload(app, settings)
      end
    else
      # Get the settings for this app
      settings = config['apps'][app]
      if !settings
        # No app, likely
        puts "App not found"
      else
        Functions.upload(app, settings)
      end
    end
    
  end
end