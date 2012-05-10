#! /usr/bin/env ruby
## Place tweetnest tweet xml from phpmyadmin in this folder
require 'rubygems'
require 'nokogiri'
require File.expand_path('../')

XML_FILE = 'tn_tweets.xml'

xml = Nokogiri::XML(File.open(File.join(File.dirname(__FILE__), XML_FILE)))
xml.css("table").each do |tweet|
  id = tweet.css('column[name = "id"]').inner_text
  tweet_id = tweet.css('column[name= "tweetid"]').inner_text
  sender_name = "simonszu"
  message = tweet.css('column[name = "text"]').inner_text
  sender_id = tweet.css('column[name = "userid"]').inner_text
  date = tweet.css('column[name = "time"]').inner_text
  source = tweet.css('column[name = "source"]').inner_text
  puts "Tweet #{id}"
  puts "Tweet-ID #{tweet_id}"
  puts "Absender #{sender_name}"
  puts "Text: #{message}"
  puts "Absender-ID: #{sender_id}"
  puts "Gesendet zum Zeitpunkt #{date}"
  puts "Gesendet mit #{source}"
  puts "#######################################"
  puts ""
end