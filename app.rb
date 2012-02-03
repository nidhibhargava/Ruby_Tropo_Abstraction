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
  r = CallNotification.get_redis()  
  redis_order_number = r.hget("id:#{params[:hash]}", "order_number")
  redis_attempts = r.hget("id:#{params[:hash]}", "attempts")

  if Integer(attempts <= 3)
    r.hset("id:#{params[:hash]}", "call_status", "Server Error")
    Resque.enqueue_in(3.minutes, Phonecall, redis_order_number)  
  else
    CallNotification.send_email(redis_order_number, 'Server Error')
  end
  t.hangup()
end

 #incomplete fires when the call was unsuccessful - such as a timeout or call failure (someone rejecting the call will usually trigger this event)  
post '/incomplete/:hash' do
  t = Tropo::Generator.new
  # Scheduling the job again in queue 
  r = CallNotification.get_redis()  

  redis_order_number = r.hget("id:#{params[:hash]}", "order_number")
  redis_attempts = r.hget("id:#{params[:hash]}", "attempts")

  if Integer(attempts <= 3)
    r.hset("id:#{params[:hash]}", "call_status", "Timeout Error")
    Resque.enqueue_in(3.minutes, Phonecall, redis_order_number)  
  else
    CallNotification.send_email(redis_order_number, 'timeout or rejecting the call')
  end
  
  t.hangup()
end

#hangup fires if the call was answered and then disconnected (reaching voicemail will usually trigger hangup)
post '/hangup/:hash' do
  t = Tropo::Generator.new
  
  r = CallNotification.get_redis()  

  redis_order_number = r.hget("id:#{params[:hash]}", "order_number")
  redis_attempts = r.hget("id:#{params[:hash]}", "attempts")

  if Integer(attempts <= 3)
    r.hset("id:#{params[:hash]}", "call_status", "Call Disconnected"
    Resque.enqueue_in(3.minutes, Phonecall, redis_order_number)  
  else    
    CallNotification.send_email(redis_order_number, 'call was answered and then disconnected reaching voicemail')
  end
  t.hangup()
end

get '/index' do
	@model = get_redis()
	erb :index
end
