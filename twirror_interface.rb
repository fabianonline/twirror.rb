# This file here creates some nice HTTP action for viewing the contents of the twirror DB
require './twirror'

get '/' do
	erb :index
end

get '/stats' do
	@sender = 'fabianonline'
	@stats = Tweet.stats(:daily, @sender)
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
    
    if params[:order] == 'asc'
        order = "date"
    else
        order = "date DESC"
    end

	limit = params[:limit] || 500

	
	@tweets = Tweet.find(:all, :conditions=>condition_values.unshift(condition_names.join(" AND ")), :order=>order, :limit=>limit)
	erb :tweets
end
