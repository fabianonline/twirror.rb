require 'twitter_oauth'
$stdout.sync = true

def get_tweets(client, settings={})
	raise "Missing parameters!" unless [:start, :description, :twitter_method, :tweet_add_method].all?{|e| settings.has_key?(e)}

	print "#{settings[:description].ljust(25)}: "
	parameters = {"count"=>"200", "since_id"=>settings[:start]}
	min_id = nil
	counter = 0
	objects = []
    begin
        temp = client.send(settings[:twitter_method], parameters)
		print '#'
		if temp.kind_of?(Array)
			temp.each do |t|
				tweet = Tweet.send(settings[:tweet_add_method], t)
				print "."
				counter+=1
				if min_id==nil || min_id>tweet.tweet_id
					min_id = tweet.tweet_id
				end
				objects << tweet
			end
		else
			raise "Got error. Aborting."
		end
		parameters["max_id"] = min_id-1 rescue nil
    end while temp.kind_of?(Array) && temp.length > 0 && min_id!=nil
	puts " (#{counter})"
	return objects
end

def do_update(config)
    client = TwitterOAuth::Client.new(
        :consumer_key =>    config['twitter']['consumer']['token'],
        :consumer_secret => config['twitter']['consumer']['secret'],
        :token =>           config['twitter']['user']['token'],
        :secret =>          config['twitter']['user']['secret'])

    unless client.authorized?
        puts "Konnte nicht mit Twitter authorisieren..."
        Process.exit
    end

	all_objects = []

    start = Tweet.maximum('tweet_id', :conditions=>'dm = 0') || 1

	all_objects += get_tweets(client, :start=>start, :description=>"Timeline", :twitter_method=>:home_timeline, :tweet_add_method=>:add)
	all_objects += get_tweets(client, :start=>start, :description=>"Mentions", :twitter_method=>:mentions, :tweet_add_method=>:add)
	all_objects += get_tweets(client, :start=>start, :description=>"Sent Tweets", :twitter_method=>:user_timeline, :tweet_add_method=>:add)

    start = Tweet.maximum('tweet_id', :conditions=>'dm = 1') || 1

	all_objects += get_tweets(client, :start=>start, :description=>"Received DMs", :twitter_method=>:messages, :tweet_add_method=>:add_dm)
	all_objects += get_tweets(client, :start=>start, :description=>"Sent DMs", :twitter_method=>:sent_messages, :tweet_add_method=>:add_dm)


	counter = 0
	print "Saving data to DB:".ljust(25)
	all_objects.sort_by{|obj| obj.date}.each do |obj|
		if obj.save
			counter += 1
			print "."
		else
			print "#"
		end
	end
	puts "  (#{counter}/#{all_objects.count})"
end
