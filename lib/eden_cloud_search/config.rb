require "singleton"

module CloudSearch
  class MissingConfigurationError < StandardError
    def initialize(parameter_name)
      super "Missing '#{parameter_name}' configuration parameter"
    end
  end

  module ConfigurationChecking
    private

    def check_configuration_parameters
      %w(domain_id domain_name).each do |config|
        raise MissingConfigurationError.new(config) if CloudSearch.config[config].nil?
      end
    end
  end

  class Config
    include Singleton

    attr_accessor :api_version
    attr_accessor :configuration_url
    attr_accessor :domain_id
    attr_accessor :domain_name
    attr_accessor :document_url
    attr_accessor :region
    attr_accessor :search_url

    def [](config)
      self.__send__(config)
    end

    def api_version
      @api_version ||= "2011-02-01"
    end

    def configuration_url
      @configuration_url ||= "https://cloudsearch.#{self.region}.amazonaws.com"
    end

    def document_url
      @document_url ||= "http://doc-#{base_path}"
    end

    def region
      @region ||= "us-east-1"
    end

    def search_url
      @search_url ||= "http://search-#{base_path}"
    end

    private

    def base_path
      "#{self.domain_name}-#{self.domain_id}.#{self.region}.cloudsearch.amazonaws.com/#{self.api_version}"
    end
  end
end

