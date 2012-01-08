# This script updates the DB with the new written tweets.
require 'twitter_oauth'
$stdout.sync = true

def do_update(config)
    client = TwitterOAuth::Client.new( # Reads the config and tries to connect to twitter
        :consumer_key =>    config['twitter']['consumer']['token'],
        :consumer_secret => config['twitter']['consumer']['secret'],
        :token =>           config['twitter']['user']['token'],
        :secret =>          config['twitter']['user']['secret'])

    unless client.authorized? # If the connection fails, do some mimimi and quit
        puts "Konnte nicht mit Twitter authorisieren..."
        Process.exit
    end


    start = Tweet.maximum('tweet_id', :conditions=>'dm = 0') || 1 # Set the start value to begin the search with

    #puts "Tweets (home_timeline)"          # Ist das FDP oder kann das weg?
    #puts "======================"
    #puts "since_id: #{start}"

    print "home_timeline... " # Prints "home_timeline..." :P

    page = 1 # Set some helper variables to default values
    response = []

    begin
        #puts "Hole Page #{page}..."
        temp = client.home_timeline({"count"=>"200", "since_id"=>start, "page"=>page}) # Stores the last 200 Tweets in a temp variable
        response = response + temp # ...and concats it with the response
        page += 1
    end while temp.kind_of?(Array) && temp.length > 150 # Repeat while the response is still a valid array, and new temp stuff has more than 150 elements

    #puts "Anzahl Tweets: #{response.length}"
    print "#{response.length}... " # Prints the length of the response for logging purpose

    response.reverse.each do |r| # Roll up the response array from behind and add the tweets to the DB
        Tweet.add(r)
    end

    puts "fertig." # SUCCESS!!!!!!einself!!

    if true # Needless condition kicks ass
        puts "Sent Tweets"
        page = 1
        response = []
        begin
            puts "Hole Page #{page}..."
            temp = client.user_timeline({"count"=>200, "page"=>page}) rescue []
            response = response + temp
            page += 1
        end while temp.kind_of?(Array) && temp.length > 150 # Repeats all the stuff from above again. But now for sent tweets
        puts "Anzahl Tweets: #{response.length}"
        response.reverse.each do |r|
            Tweet.add(r)
            print '.'
        end
        puts ""
        puts ""
    end

    start = Tweet.maximum('tweet_id', :conditions=>'dm = 1') || 1 # Repeat everything from above with the DMs

    print "direct_messages... "
    #puts "Direct Messages"
    #puts "==============="
    #puts "since_id: #{start}"

    page = 1
    response = []

    #puts "Hole empfangene DMs..." # Yep
    print "received... "
    begin
        #puts "Page #{page}..."
        temp = client.messages({"count"=>"200", "since_id"=>start, "page"=>page})
        response = response + temp
        page += 1
    end while temp.kind_of?(Array) && temp.length > 150



    #puts "Hole gesendete DMs..." # Yep
    print "sent... "
    page = 1
    begin
        #puts "Page #{page}..."
        temp = client.sent_messages({"count"=>200, "since_id"=>start, "page"=>page})
        response = response + temp
        page += 1
    end while temp.kind_of?(Array) && temp.length > 150

    print "#{response.length}... "
    #puts "Anzahl DMs: #{response.length}"

    response.reverse.each do |r|
        Tweet.add_dm(r)
        #print "."
    end

    puts "fertig." # Success again. AWESOME!
    puts ""
end
