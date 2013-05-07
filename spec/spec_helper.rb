require "bundler"
Bundler.require(:default, :development)

require "simplecov"
SimpleCov.start

require "eden_cloud_search"

CloudSearch.configure do |config|
  config.domain_id   = "pl6u4t3elu7dhsbwaqbsy3y6be"
  config.domain_name = "imdb-movies"
end

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each do |file|
  require file
end

