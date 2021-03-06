require './rubytropo.rb'

describe CallNotification do

  it 'should return the redis instance'do
    r = CallNotification.get_redis
    r.should_not be_nil
  end
  
  it 'should return tropo response'do
    tropo = CallNotification.call_tropo(111111)
    tropo.should_not be_nil
  end
  
  it 'should return success after email is send'do
    tropo = CallNotification.send_email(111111, 'error')
    #tropo.should_be??
  end
  
end



