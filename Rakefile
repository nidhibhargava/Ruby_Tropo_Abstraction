require "bundler/setup"
Bundler.require(:default)
require './rubytropo'
require 'resque/tasks'
require 'resque_scheduler/tasks'

task "resque:setup" do
    require 'resque'
    require 'resque_scheduler'
    require 'resque/scheduler'
    ENV['QUEUE'] = '*'

  if ENV.has_key?("REDISTOGO_URL")
    uri = URI.parse(ENV["REDISTOGO_URL"])
    Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  end
end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"
