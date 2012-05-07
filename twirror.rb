#!/usr/bin/ruby

# Require some nice libraries
require 'rubygems'
require 'active_record'
require 'active_support'
require 'getopt/long'
require 'yaml'

# Extend the Namespace for the Getopt Gem
include Getopt

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

# Define a tweet as an object with some allocation between the tweetdata and the fields of the database
class Tweet < ActiveRecord::Base
    validates_uniqueness_of :tweet_id, :scope=>:dm # First of all validate that the tweet is no duplicate
    
    def self.add(tweet) # Execute this method when adding a new tweet to the DB
        return unless tweet # If the given argument is no real tweet, return and do nothing
        t = Tweet.new # Otherwise, create a new tweet and fill it with content. Look below to see how.
        t.tweet_id = tweet["id"]
        t.sender_name = tweet["retweeted_status"]["user"]["screen_name"] rescue tweet["user"]["screen_name"]
        t.message = tweet["text"]
        t.sender_id = tweet["retweeted_status"]["user"]["id"] rescue tweet["user"]["id"]
        t.retweeted_by_name = tweet["user"]["screen_name"]if tweet["retweeted_status"]
        t.retweeted_by_id = tweet["user"]["id"] if tweet["retweeted_status"]
        t.geo_lat = tweet["geo"]["coordinates"][0] rescue nil
        t.geo_long = tweet["geo"]["coordinates"][1] rescue nil
        t.date = Time.parse(tweet["created_at"])
        t.json_data = tweet.to_json
        t.source = tweet["source"]
        t.sender_friends = tweet["user"]["friends_count"] rescue nil
        t.sender_followers = tweet["user"]["followers_count"] rescue nil
        t.dm = 0
		t # Return the tweet
    end

    def self.add_dm(tweet) # Execute this method, when adding a new DM to the DB
        return unless tweet # If the given argument is no real tweet, return and do nothing
        t = Tweet.new # Otherwise, create a new tweet and fill it with content. Look below to see how.
        t.tweet_id = tweet["id"]
        t.sender_name = tweet["sender"]["screen_name"]
        t.message = tweet["text"]
        t.sender_id = tweet["sender_id"]
        t.date = Time.parse(tweet["created_at"])
        t.json_data = tweet.to_json
        t.dm = 1
        t.recipient_name = tweet["recipient"]["screen_name"]
        t.recipient_id = tweet["recipient_id"]
		t
    end

    def self.stats(period, username) # Execute this method for creating stats over the given period
        start = case period # First, define the time range for the stats
			when :daily then "DATE(date)"
			when :weekly then "SUBDATE(DATE(date), WEEKDAY(date))"
			when :monthly then "SUBDATE(DATE(date), DAYOFMONTH(date)-1)"
			else raise "Unknown period"
		end
		hash = {}
		Tweet.find(:all, :conditions=>{:sender_name=>username}, :select=>"id, DATE(date) AS date, COUNT(id) AS count_value", :group=>group).each do |entry|
			hash[entry.date.to_date] = entry.count_value
		end
		hash.sort
	end

    def self.info # Execute this method for getting some info about the tweets in the DB
        puts "Tweets in DB: #{Tweet.count}"
        puts "Neuester Tweet: #{Tweet.last.date} (vor #{(Time.now - Tweet.last.date) / 60} Minuten)"
    end

    def self.get_user_id(username) # Execute this method for getting the user id for a given username
        result = Tweet.find_all_by_sender_name(username, :group=>:sender_id)
        raise "Ambiguous Username... Houston, we have a problem!" if result.count > 1 # Raises exception if username is not unique
        raise "User not found" if result.empty? # Raises exception if username is not found
        result.first.sender_id
    end
end




include Getopt # Include Getopt. It's a library to automatically parse command line parameters

opt = Getopt::Long.getopts(
    ['--update', '-u', BOOLEAN],
    ['--info', '-i', BOOLEAN],
    ['--nagios', BOOLEAN]
) rescue {}


if opt["update"]
    require "#{File.dirname((File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__))}/updater.rb"
    do_update(config)
elsif opt["nagios"]
    diff = Time.now - Tweet.last.date # in Sekunden
    puts "Neuester Tweet ist #{(diff / 60).round} Minuten alt."
    exit 2 if diff > (24*60*60) # 24 Stunden - CRITICAL
    exit 1 if diff > (12*60*60) # 12 Stunden - WARNING
    exit 0 # Alles OK
elsif opt["info"]
    Tweet.info
end

