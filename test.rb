require './rubytropo.rb'
require './app.rb'
require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_getsession
    post '/getsession.json', :data => '{\"territory_name\":\"Hungry Buffs\",\"restaurant_phone_number\":\"1112223333\",\"order_number\":\"1232131\"}'
    assert last_response.ok?
    aassert last_response.body.include?('EatBmore')
  end

  def test_it_says_hello_to_a_person
    get '/', :name => 'Nidhi'
    assert last_response.body.include?('Nidhi')
  end
end

