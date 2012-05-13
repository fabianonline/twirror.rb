#! /usr/bin/env ruby
## Place tweetnest tweet xml from phpmyadmin in this folder
require 'rubygems'
require 'nokogiri'
require 'php_serialize'
require '../twirror.rb'

XML_FILE = 'tn_tweets.xml'

xml = Nokogiri::XML(File.open(File.join(File.dirname(__FILE__), XML_FILE)))
print "Fehler in Tweet # "
xml.css("table").each do |tweet|
  id = tweet.css('column[name = "id"]').inner_text
  tweet_id = tweet.css('column[name= "tweetid"]').inner_text
  sender_name = "simonszu"
  message = tweet.css('column[name = "text"]').inner_text
  sender_id = tweet.css('column[name = "userid"]').inner_text
  date = tweet.css('column[name = "time"]').inner_text
  source = tweet.css('column[name = "source"]').inner_text
  begin
    extra = PHP.unserialize(tweet.css('column[name = "extra"]').inner_text)
  end
  
  puts "Tweet #{id}"
  p extra
  #puts "Tweet-ID #{tweet_id}"
  #puts "Absender #{sender_name}"
  #puts "Text: #{message}"
  #puts "Absender-ID: #{sender_id}"
  #puts "Gesendet zum Zeitpunkt #{date}"
  #puts "Gesendet mit #{source}"
  #puts "#######################################"
  puts "Ready for next"
  puts ""
end