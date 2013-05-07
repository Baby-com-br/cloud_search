# require "em-http"
require "rest_client"
require "json"
require "eden_cloud_search/version"

module CloudSearch
  autoload :Config,                          "eden_cloud_search/config"
  autoload :ConfigurationChecking,           "eden_cloud_search/config"
  autoload :Searcher,                        "eden_cloud_search/searcher"
  autoload :SearchResponse,                  "eden_cloud_search/search_response"
  autoload :Indexer,                         "eden_cloud_search/indexer"
  autoload :Document,                        "eden_cloud_search/document"
  autoload :InvalidDocument,                 "eden_cloud_search/invalid_document"
  autoload :InsufficientParametersException, "eden_cloud_search/exceptions"

  def self.config
    Config.instance
  end

  def self.configure(&block)
    block.call(self.config)
  end
end

