#!/usr/bin/ruby

# Require some nice libraries
require 'rubygems'
Bundler.require
require 'tweet.rb'

include Getopt # Include Getopt. It's a library to automatically parse command line parameters

# Read the config from the config.yml YAML file
config = YAML.load_file("#{File.dirname((File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__))}/config.yml")

# Let ActiveRecord connect to the database using the credentials out of the config
ActiveRecord::Base.establish_connection(
    :adapter => 'mysql',
    :host =>     config['mysql']['host'],
    :username => config['mysql']['username'],
    :password => config['mysql']['password'],
    :database => config['mysql']['database'],
    :encoding => config['mysql']['encoding'])


# Get the options from the command line
opt = Getopt::Long.getopts(
    ['--update', '-u', BOOLEAN],
    ['--info', '-i', BOOLEAN],
    ['--nagios', BOOLEAN]
) rescue {}


# Call the tweet update process
if opt["update"]
    require "#{File.dirname((File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__))}/updater.rb"
    do_update(config)
    
# Call a nagios compatible output for watching the script
elsif opt["nagios"]
    diff = Time.now - Tweet.last.date # in Sekunden
    puts "Neuester Tweet ist #{(diff / 60).round} Minuten alt."
    exit 2 if diff > (24*60*60) # 24 Stunden - CRITICAL
    exit 1 if diff > (12*60*60) # 12 Stunden - WARNING
    exit 0 # Alles OK
    
# Call the Info (of whatever, has to be checked)
elsif opt["info"]
    Tweet.info
end

