require './twirror'

get '/' do
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
	
	@tweets = Tweet.find(:all, :conditions=>condition_values.unshift(condition_names.join(" AND ")), :order=>"date DESC")
	erb :tweets
end
