require './rubytropo.rb'


post '/getsession.json' do
  req_body = request.body.read
  json_params = JSON.parse(req_body)
  order_number = CallNotification.save_to_redis(json_params)    
  Resque.enqueue(Phonecall, json_order_number)
end 

post '/call.json' do
  req_body = request.body.read
  json_params = JSON.parse(req_body)["session"]["parameters"]
  hash = json_params["hash"]  
  CallNotification.call_tropo(hash)
end

#error will fire if something went wrong at the server level (i.e., the call never went out at all)
post '/error/:hash' do
  t = Tropo::Generator.new
  req_body=request.body.read
  # Log Error Here
  t.hangup()
end

 #incomplete fires when the call was unsuccessful - such as a timeout or call failure (someone rejecting the call will usually trigger this event)  
post '/incomplete/:hash' do
  t = Tropo::Generator.new
  # Scheduling the job again in queue 
  r = CallNotification.get_redis()  

  redis_order_number = r.hget("id:#{params[:hash]}", "order_number")
  redis_attempts = r.hget("id:#{params[:hash]}", "attempts")

  Resque.enqueue_in(3.minutes, Phonecall, redis_order_number)
  
  t.hangup()
end

#hangup fires if the call was answered and then disconnected (reaching voicemail will usually trigger hangup)
post '/hangup/:hash' do
  t = Tropo::Generator.new
  # Log Error Here
  t.hangup()
end

post '/email/:hash' do 
  #get redis connections  
  r = CallNotification.get_redis()  
  redis_order_number = r.hget("id:#{params[:hash]}", "order_number")

  #email to single user:
  RestClient.post "https://api:key-3xrun8ueczhw1r4sk697ssggjgimrwo6"\
  "@api.mailgun.net/v2/app2325333.mailgun.org/messages",
  :from => "Excited User <nbhargava@localupsolutions.com>",
  :to => "nbhargava@localupsolutions.com",
  :subject => "Hello",
  :text => "Testing some Mailgun awesomeness!",
  "o:deliverytime" => "Fri, 25 Oct 2011 23:10:10 -0000"
end

get '/index' do
	@model = get_redis()
	erb :index
end
