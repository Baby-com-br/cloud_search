# require "em-http"
require "rest_client"
require "json"
require "cloud_search/version"

module CloudSearch
  autoload :Config,                "cloud_search/config"
  autoload :ConfigurationChecking, "cloud_search/config"
  autoload :Searcher,              "cloud_search/searcher"
  autoload :SearchResponse,        "cloud_search/search_response"
  autoload :Indexer,               "cloud_search/indexer"
  autoload :Document,              "cloud_search/document"
  autoload :InvalidDocument,       "cloud_search/invalid_document"
  autoload :InsufficientParametersException, "cloud_search/exceptions"

  def self.config
    Config.instance
  end

  def self.configure(&block)
    block.call(self.config)
  end
end

