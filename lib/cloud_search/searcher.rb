require 'uri'

module CloudSearch
  class Searcher
    include ::CloudSearch::ConfigurationChecking

    attr_reader :weights

    def initialize
      @response = SearchResponse.new
      @query = ''
      @boolean_queries = {}
      @filters = {}
      @facets = []
      @fields = []
    end

    def search
      cloud_search_response = RestClient.get url
      @response.http_code   = cloud_search_response.code
      @response.body        = cloud_search_response.body

      @response
    end

    def with_query(query)
      @query = query || ''
      self
    end

    def with_boolean_query(queries)
      queries.each do |k, v|
        queries[k] = [v] unless v.respond_to? :map
      end

      @boolean_queries.merge!(queries)
      self
    end

    def with_filters(filters)
      @filters = filters
      self
    end

    def with_facets(*facets)
      @facets += facets
      self
    end

    def ranked_by(rank_expression)
      @rank = rank_expression
      self
    end

    def with_fields(*fields)
      @fields += fields
      self
    end

    def with_items_per_page(items_per_page)
      @response.items_per_page = items_per_page
      self
    end

    def at_page(page)
      @page_number = (page && page < 1) ? 1 : page
      self
    end

    def url
      check_configuration_parameters
      raise InsufficientParametersException.new('At least query or boolean_query must be defined.') if (@query.empty? && @boolean_queries.empty?)

      params = {
        'q' => query,
        'bq' => boolean_query,
        'size' => items_per_page,
        'start' => start,
        'return-fields' => URI.escape(@fields.join(",")),
        'facet' => @facets.join(','),
        'rank' => @rank
      }
      params.merge! @filters
      params.delete_if { |_,v| v.nil? || v.to_s.empty? }

      querystring = params.map { |k,v| "#{k}=#{v}" }.join('&')
      "#{CloudSearch.config.search_url}/search?#{querystring}"
    end

    def items_per_page
      @response.items_per_page
    end

    def page_number
      @page_number or 1
    end

    def start
      return 0 if page_number <= 1
      (items_per_page * (page_number - 1))
    end

    private

    def query
      CGI::escape(@query)
    end

    def boolean_query
      return '' if @boolean_queries.empty?

      bq = @boolean_queries.map do |key, values|
        "#{key}:'#{values.map { |e| CGI::escape(e) }.join('|')}'"
      end.join(' ')
      "(and #{bq})"
    end

    def filter_expression
      @filters.join("&")
    end
  end
end

