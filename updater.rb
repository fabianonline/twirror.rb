require 'twitter_oauth'
$stdout.sync = true

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

	objects = []


    start = Tweet.maximum('tweet_id', :conditions=>'dm = 0') || 1

    print "Timeline:             "
	parameters = {"count"=>"200", "since_id"=>start}
	min_id = nil
	counter = 0
    begin
        temp = client.home_timeline(parameters)
		print '#'
		if temp.kind_of?(Array)
			temp.each do |t|
				tweet = Tweet.add(t)
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


    print "Mentions:             "
	parameters = {"count"=>"200", "since_id"=>start}
	min_id = nil
	counter = 0
    begin
        temp = client.mentions(parameters)
		print '#'
		if temp.kind_of?(Array)
			temp.each do |t|
				tweet = Tweet.add(t)
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


    print "Sent Tweets:          "
	parameters = {"count"=>"200", "since_id"=>start}
	min_id = nil
	counter = 0
	begin
		temp = client.user_timeline(parameters)
		print '#'
		if temp.kind_of?(Array)
			temp.each do |t|
				tweet = Tweet.add(t)
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



    start = Tweet.maximum('tweet_id', :conditions=>'dm = 1') || 1

    print "Received DMs:         "
	parameters = {"count"=>"200", "since_id"=>start}
	min_id = nil
	counter = 0
    begin
        temp = client.messages(parameters)
		print '#'
		if temp.kind_of?(Array)
			temp.each do |t|
				tweet = Tweet.add_dm(t)
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

    print "Sent DMs:             "
	parameters = {"count"=>"200", "since_id"=>start}
	min_id = nil
	counter = 0
    begin
        temp = client.sent_messages(parameters)
		print '#'
		if temp.kind_of?(Array)
			temp.each do |t|
				tweet = Tweet.add_dm(t)
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

	counter = 0
	print "Saving data to DB:    "
	objects.sort_by{|obj| obj.date}.each do |obj|
		if obj.save
			counter += 1
			print "."
		else
			print "#"
		end
	end
	puts "  (#{counter}/#{objects.count})"
end
