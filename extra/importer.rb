require './twirror'
require 'json'
require 'nokogiri'

files = Dir.glob("/home/fabian/temp/alt/blubb/twirror/fabianonline/*.xml")
i=1
files.each do |file|
	print "#{i}  "
	puts file
	xmlstr = File.open(file, "r") {|f| f.read}
	xml = Nokogiri::XML(xmlstr)
	t = Tweet.new
	t.tweet_id = xml.xpath('//id').first.content
	t.sender_name = xml.xpath('//retweeted_status/user/screen_name').first.content rescue xml.xpath('//user/screen_name').first.content
	t.message = xml.xpath('//text').first.content
    t.sender_id = xml.xpath('//retweeted_status/user/id').first.content rescue xml.xpath('//user/id').first.content
    t.retweeted_by_name = xml.xpath('//user/screen_name').first.content if xml.xpath('//retweeted_status').length>0
    t.retweeted_by_id = xml.xpath('//user/id').first.content if xml.xpath('//retweeted_status').length>0
    t.geo_lat = xml.xpath('//geo/coordinates')[0].content rescue nil
    t.geo_long = xml.xpath('//geo/coordinates')[1].content rescue nil
    t.date = Time.parse(xml.xpath('//created_at').first.content)
    t.json_data = xmlstr
    t.source = xml.xpath('//source').first.content
    t.sender_friends = xml.xpath('//user/friends_count').first.content rescue nil
    t.sender_followers = xml.xpath('//user/followers_count').first.content rescue nil
    t.dm = 0
	t.save
	i+=1
end

