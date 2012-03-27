#!/usr/bin/ruby

require 'rubygems'
require 'active_record'
require 'active_support'
require 'getopt/long'
require 'yaml'

config = YAML.load_file("#{File.dirname((File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__))}/config.yml")

ActiveRecord::Base.establish_connection(
    :adapter => 'mysql',
    :host =>     config['mysql']['host'],
    :username => config['mysql']['username'],
    :password => config['mysql']['password'],
    :database => config['mysql']['database'],
    :encoding => config['mysql']['encoding'])

class Tweet < ActiveRecord::Base
    validates_uniqueness_of :tweet_id, :scope=>:dm
    def self.add(tweet)
        return unless tweet
        t = Tweet.new
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
        t.save
    end

    def self.add_dm(tweet)
        return unless tweet
        t = Tweet.new
        t.tweet_id = tweet["id"]
        t.sender_name = tweet["sender"]["screen_name"]
        t.message = tweet["text"]
        t.sender_id = tweet["sender_id"]
        t.date = Time.parse(tweet["created_at"])
        t.json_data = tweet.to_json
        t.dm = 1
        t.recipient_name = tweet["recipient"]["screen_name"]
        t.recipient_id = tweet["recipient_id"]
        t.save
    end

	def self.stats(period, username)
		group = case period
			when :daily then "DATE(date)"
			when :weekly then "SUBDATE(DATE(date), WEEKDAY(date))"
			when :monthly then "SUBDATE(DATE(date), DAYOFMONTH(date)-1)"
		end
		hash = {}
		Tweet.find(:all, :conditions=>{:sender_name=>username}, :select=>"id, DATE(date) AS date, COUNT(id) AS count_value", :group=>group).each do |entry|
			hash[entry.date.to_date] = entry.count_value
		end
		hash.sort
	end

	def self.print_stats(period, username)
		result = self.stats(period, username).last(30)
		max = result.inject(0){|memo, day| (day[1]>memo ? day[1] : memo)}
		faktor = 150.0 / max
		result.each do |day|
			color = case day[0].wday
				when 0 then "\e[31m"
				else "\e[0m"
			end
			puts "%s%s\e[0m: (%4d) [%-150s]" % [color, day[0].to_s, day[1], '#'*(day[1]*faktor)]
		end
	end

    def self.info
        puts "Tweets in DB: #{Tweet.count}"
        puts "Neuester Tweet: #{Tweet.last.date} (vor #{(Time.now - Tweet.last.date) / 60} Minuten)"
    end

    def self.get_user_id(username)
        result = Tweet.find_all_by_sender_name(username, :group=>:sender_id)
        raise "Ambiguous Username... Houston, we have a problem!" if result.count > 1
        raise "User not found" if result.empty?
        result.first.sender_id
    end

    def self.nelsontweets
        ende = Date.today-Date.today.wday
        start = ende-7
        tweets = Tweet.find(:all, :conditions=>["date >= :start AND date <= :ende AND message LIKE '%#nelsontweet%'", {:start=>start, :ende=>ende}])
        tweets.each {|t| puts t.message}
        fails = tweets.collect{|t| t.message.split(" ")[0]}.select{|f| f[0]==64}
        failers = fails.inject(Hash.new(0)) {|hash, failer| hash[failer]+=1; hash}.to_a.sort_by{|elm| elm[1]}.reverse
        message = "#nelsontweet-Stats der letzten Woche: \n" + failers.collect{|elm| elm.join(": ")}.join("\n")
        exit if message.length>140
        puts message
    end
end

include Getopt

opt = Getopt::Long.getopts(
    ['--update', '-u', BOOLEAN],
    ['--help', '-h', BOOLEAN],
    ['--daily', '-d', BOOLEAN],
    ['--weekly', '-w', BOOLEAN],
    ['--monthly', '-m', BOOLEAN],
    ['--search', '-s', BOOLEAN],
    ['--from', '-f', REQUIRED],
    ['--contains', '-c', REQUIRED],
    ['--info', '-i', BOOLEAN],
    ['--create-locations-file', BOOLEAN],
    ['--create-kml', BOOLEAN],
    ['--nagios', BOOLEAN],
    ['--nelsontweets', BOOLEAN],
    ['--bitmap', BOOLEAN]
) rescue {}


if opt["update"]
    require "#{File.dirname((File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__))}/updater.rb"
    do_update(config)
end

if opt["nagios"]
    diff = Time.now - Tweet.last.date # in Sekunden
    puts "Neuester Tweet ist #{(diff / 60).round} Minuten alt."
    exit 2 if diff > (24*60*60) # 24 Stunden - CRITICAL
    exit 1 if diff > (12*60*60) # 12 Stunden - WARNING
    exit 0 # Alles OK
end

conditions = []

if opt["contains"]
    contains = opt["contains"]
    contains = [contains] if contains.is_a?(String)
    contains.each do |string|
        conditions.add["message LIKE '%?%'", string]
    end
end

unless conditions.empty?
    tweets = Tweet.all(:conditions => conditions.join(" and "))
    puts tweets.inspect
end

if opt["hourly"]
    Tweet.print_stats(:hourly, config['twitter']['username'])
elsif opt["daily"]
    Tweet.print_stats(:daily, config['twitter']['username'])
elsif opt["weekly"]
    Tweet.print_stats(:weekly, config['twitter']['username'])
elsif opt["monthly"]
    Tweet.print_stats(:monthly, config['twitter']['username'])
elsif opt["help"]
    puts "help"
elsif opt["info"]
    Tweet.info
elsif opt["nelsontweets"]
    Tweet.nelsontweets
elsif opt["create-locations-file"]
    tweets = Tweet.find(:all, :conditions=>"sender_name='#{config['twitter']['username']}' && geo_lat is not null && geo_long is not null", :order=>"date DESC", :limit=>500)
    puts "pts=[" + tweets.map{|t| "(#{t.geo_long}, #{t.geo_lat})"}.join(",\n") + "]"
elsif opt["create-kml"]
    puts '<?xml version="1.0" encoding="UTF-8"?>'
    puts '<kml xmlns="http://earth.google.com/kml/2.2">'
    puts '<Document>'
    puts '<name>places.kml</name>'
    puts '<Folder><name>Locations</name><open>1</open>'
    puts '<Style id="a">  <PolyStyle><color>88ff0000</color></PolyStyle></Style>'
    #puts '<Style id="smallPolyStyle"><PolyStyle><color>88ff0000</color></PolyStyle></Style>'
    decimals=2
    tweets = Tweet.find(:all, :conditions=>"sender_name='#{config['twitter']['username']}' && geo_lat is not null && geo_long is not null", :order=>"date DESC", :select=>"*, CONCAT(ROUND(geo_lat, #{decimals}), ', ', ROUND(geo_long, #{decimals})) as geo", :group=>"geo")
    tweets.each do |t|
        long = t.geo_lat.round(decimals)
        lat = t.geo_long.round(decimals)
        long_ = (t.geo_lat+1.0/(10**decimals)).round(decimals)
        lat_ = (t.geo_long+1.0/(10**decimals)).round(decimals)
        coords = "#{lat},#{long},0 #{lat_},#{long},0 #{lat_},#{long_},0 #{lat},#{long_},0"
        puts "<Placemark><name>#{t.id}</name><styleUrl>#a</styleUrl><Polygon><tessellate>1</tessellate><outerBoundaryIs><LinearRing><coordinates>#{coords}</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>"
        #puts "<Placemark><name>#{t.id}</name><Point><coordinates>#{coords}</coordinates></Point></Placemark>"
    end
    decimals=3
    tweets = Tweet.find(:all, :conditions=>"sender_name='#{config['twitter']['username']}' && geo_lat is not null && geo_long is not null", :order=>"date DESC", :select=>"*, CONCAT(ROUND(geo_lat, #{decimals}), ', ', ROUND(geo_long, #{decimals})) as geo", :group=>"geo")
    tweets.each do |t|
        long = t.geo_lat.round(decimals)
        lat = t.geo_long.round(decimals)
        long_ = (t.geo_lat+1.0/(10**decimals)).round(decimals)
        lat_ = (t.geo_long+1.0/(10**decimals)).round(decimals)
        coords = "#{lat},#{long},0 #{lat_},#{long},0 #{lat_},#{long_},0 #{lat},#{long_},0"
        puts "<Placemark><name>#{t.id}</name><styleUrl>#a</styleUrl><Polygon><tessellate>1</tessellate><outerBoundaryIs><LinearRing><coordinates>#{coords}</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>"
    end
    puts "</Folder></Document></kml>"
elsif opt["bitmap"]
    require 'RMagick'
    PER_HOUR = 20
    canvas = Magick::Image.new(356*2, 24*PER_HOUR)
    gc = Magick::Draw.new
    gc.stroke('lightcyan2')
    (1..23).each do |h|
        gc.line(0, h*PER_HOUR, 100000, h*PER_HOUR)
    end
    gc.stroke('blue')
    [6,12,18].each do |h|
        gc.line(0, h*PER_HOUR, 100000, h*PER_HOUR)
    end

    gc.stroke('black')
    gc.fill('black')
    start = (356*2).days.ago
    tweets = Tweet.find(:all, :conditions=>{:date=>start..Time.now, :sender_name=>'fabianonline'})
    for tweet in tweets do
        x = tweet.date.to_date - start.to_date
        y = (tweet.date.hour*60 + tweet.date.min)*PER_HOUR/60
        gc.rectangle(x-1, y-1, x+1, y+1)
        #gc.point(x, y)
    end
    gc.draw(canvas)
    canvas.write("bitmap.png")
end


