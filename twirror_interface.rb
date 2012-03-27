require './twirror'

get '/' do
	erb :index
end

get '/stats' do
	@sender = 'fabianonline'
	@stats = Tweet.stats(:daily, @sender)
	erb :stats
end

post '/search' do
	condition_names = []
	condition_values = []
	
	if params[:containing] && params[:containing].length>0
		condition_names << "MATCH (message) AGAINST (?)"
		condition_values << params[:containing]
	end
	
	if params[:sender] && params[:sender].length>0
        id = Tweet.get_user_id(params[:sender])
		condition_names << "sender_id = ?"
		condition_values << id
	end

    if params[:mentions] == 'only'
        condition_names << "LEFT(message, 1)='@'"
    end

    if params[:mentions] == 'none'
        condition_names << "LEFT(message, 1)!='@'"
    end
    
    if params[:order] == 'asc'
        order = "date"
    else
        order = "date DESC"
    end

	
	@tweets = Tweet.find(:all, :conditions=>condition_values.unshift(condition_names.join(" AND ")), :order=>order)
	erb :tweets
end
