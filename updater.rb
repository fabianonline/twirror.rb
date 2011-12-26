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


    start = Tweet.maximum('tweet_id', :conditions=>'dm = 0') || 1

    #puts "Tweets (home_timeline)"
    #puts "======================"
    #puts "since_id: #{start}"

    print "home_timeline... "

    page = 1
    response = []

    begin
        #puts "Hole Page #{page}..."
        temp = client.home_timeline({"count"=>"200", "since_id"=>start, "page"=>page})
        response = response + temp
        page += 1
    end while temp.kind_of?(Array) && temp.length > 150

    #puts "Anzahl Tweets: #{response.length}"
    print "#{response.length}... "

    response.reverse.each do |r|
        Tweet.add(r)
    end

    puts "fertig."

    if true
        puts "Sent Tweets"
        page = 1
        response = []
        begin
            puts "Hole Page #{page}..."
            temp = client.user_timeline({"count"=>200, "page"=>page}) rescue []
            response = response + temp
            page += 1
        end while temp.kind_of?(Array) && temp.length > 150
        puts "Anzahl Tweets: #{response.length}"
        response.reverse.each do |r|
            Tweet.add(r)
            print '.'
        end
        puts ""
        puts ""
    end

    start = Tweet.maximum('tweet_id', :conditions=>'dm = 1') || 1

    print "direct_messages... "
    #puts "Direct Messages"
    #puts "==============="
    #puts "since_id: #{start}"

    page = 1
    response = []

    #puts "Hole empfangene DMs..."
    print "received... "
    begin
        #puts "Page #{page}..."
        temp = client.messages({"count"=>"200", "since_id"=>start, "page"=>page})
        response = response + temp
        page += 1
    end while temp.kind_of?(Array) && temp.length > 150



    #puts "Hole gesendete DMs..."
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

    puts "fertig."
    puts ""
end
