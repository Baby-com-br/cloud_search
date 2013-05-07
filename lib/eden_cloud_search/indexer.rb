module CloudSearch
  class Indexer
    include ::CloudSearch::ConfigurationChecking

    def initialize
      @documents = []
    end

    def <<(document)
      raise InvalidDocument.new(document) unless document.valid?
      @documents << document
    end

    alias :add :<<

    def documents
      @documents.freeze
    end

    def index
      cloud_search_response = RestClient.post url, documents_json, headers
      message               = "#{cloud_search_response.code} - #{cloud_search_response.length} bytes\n#{url}\n"
      response              = JSON.parse cloud_search_response.body

      [response, message]
    end

    private

    def headers
      {"Content-Type" => "application/json", "Accept" => "application/json" }
    end

    def documents_json
      JSON.unparse(@documents.map(&:as_json))
    end

    def url
      check_configuration_parameters

      "#{CloudSearch.config.document_url}/documents/batch"
    end
  end
end
