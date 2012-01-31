require "bundler/setup"
Bundler.require(:default)

require 'net/http'
require 'active_support/time'

module Phonecall
   @queue = :Phonecall
   def self.perform(order_number)
      r = get_redis()
      
       # Pulling the items out of the hash into a variable for readability 
      redis_territory_name = r.hget("id:#{order_number}", "territory_name")
      redis_restaurant_phone_number = r.hget("id:#{order_number}", "restaurant_phonenumber")
      redis_order_number = r.hget("id:#{order_number}", "order_number")

      token = "0ae54b34467d494485e7b0294802ec569d274a5bf89e437284c6654d1f7fb021021cfae8229c48e03661d1c9"
      tropo_session_api = "api.tropo.com"
      tropo_path = "/1.0/sessions?action=create&token=#{token}&phone=#{redis_restaurant_phone_number}&territory=#{redis_territory_name}&hash=#{redis_order_number}"

      http = Net::HTTP.new tropo_session_api
      http.get tropo_path
    end
end  

module CallNotification

  #get redis instance
  def get_redis()
    if ENV.has_key?("REDISTOGO_URL")
      uri = URI.parse(ENV["REDISTOGO_URL"])
      Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    else
      Redis.new(:host => 'localhost', :port => 6379)
    end
  end
  
  def save_to_redis(jsonParam)
    r = get_redis()
    json_order_number = jsonParam['order_number']
    call_attempts = 0
       
    r.hset("id:#{json_order_number}", "territory_name", jsonParam['territory_name'])
    r.hset("id:#{json_order_number}", "restaurant_phonenumber", jsonParam['restaurant_phone_number'])
    r.hset("id:#{json_order_number}", "order_number", jsonParam['order_number'])
    r.hset("id:#{json_order_number}", "order_type", jsonParam['order_type'])
    r.hset("id:#{json_order_number}", "order_total", jsonParam['order_total'])
    r.hset("id:#{json_order_number}", "status", "none")
    r.hset("id:#{json_order_number}", "attempts", call_attempts)

    return json_order_number
  end
      
  def call_tropo(hash)
    t = Tropo::Generator.new
    # Pulling data out of redis based on our hash
    r = get_redis() 
    redis_territory_name = r.hget("id:#{hash}", "territory_name")
    redis_restaurant_phone_number = r.hget("id:#{hash}", "restaurant_phonenumber")
    redis_order_number = r.hget("id:#{hash}", "order_number")
    
    phone = "+1" + redis_restaurant_phone_number
    msg = "<speak><prosody rate='-70%'>Hello, you have a new takeout order, Please check your email for order details. The order number is, #{redis_order_number}, and the order total is 10 dollars. If you did not receive an email, please call one eight hundred 689-6613. Thank you</prosody></speak>"

    t.call(:to => phone, :from => "8143257934")
    t.say(:value => msg, :voice => "Susan")

    #error will fire if something went wrong at the server level (i.e., the call never went out at all)
    t.on(:event => 'error', :next => '/error/' + redis_order_number)
    
    #incomplete fires when the call was unsuccessful - such as a timeout or call failure (someone rejecting the call will usually trigger this event)  
    t.on(:event => 'incomplete', :next => '/incomplete/' + redis_order_number)

    #hangup fires if the call was answered and then disconnected (reaching voicemail will usually trigger hangup)
    t.on(:event => 'hangup', :next => '/hangup/' + redis_order_number)
    
    #update the orderid state after making call   
    
    t.response
  end    
end





