require './rubytropo.rb'
require 'resque'
require 'resque/server'

if ENV.has_key?("REDISTOGO_URL")
  uri = URI.parse(ENV["REDISTOGO_URL"])
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

run Rack::URLMap.new \
  "/"       => Sinatra::Application,
  "/resque" => Resque::Server.new


