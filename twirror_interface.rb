# This file here creates some nice HTTP action for viewing the contents of the twirror DB
require './twirror'

get '/' do # If root is called, show the stats erb view
	erb :stats
end

post '/search' do # If a search is requested, do the search stuff.
	condition_names = []
	condition_values = []
	
	if params[:containing] && params[:containing].length>0 # Fill the search condition to work with content search of the tweets
		condition_names << "MATCH (message) AGAINST (?)"
		condition_values << params[:containing]
	end
	
	if params[:sender] && params[:sender].length>0 # Fill the search condition to work with search after all tweets of a certain username
        id = Tweet.get_user_id(params[:sender])
		condition_names << "sender_id = ?"
		condition_values << id
	end

    if params[:mentions] == 'only' # Fill the search condition to search only in mentions
        condition_names << "LEFT(message, 1)='@'"
    end

    if params[:mentions] == 'none' # Fill the search condition to search in any tweets but mentions
        condition_names << "LEFT(message, 1)!='@'"
    end

	
	@tweets = Tweet.find(:all, :conditions=>condition_values.unshift(condition_names.join(" AND ")), :order=>"date DESC") # Search action in 3..2..1..EXECUTE
	erb :tweets # Show the tweets erb view to reveal the search results.
end
