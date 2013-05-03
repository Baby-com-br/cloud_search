require 'uri'

module CloudSearch
  class Searcher
    include ::CloudSearch::ConfigurationChecking

    attr_reader :weights

    def initialize
      @response = SearchResponse.new
      @query = ''
      @boolean_queries = {}
      @filters = []
      @facets = []
      @fields = []
      @facets_constraints = {}
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

    def with_filter(filter)
      @filters << filter
      self
    end

    def with_facets(*facets)
      @facets += facets
      self
    end

    def with_facet_constraints(facets_constraints)
      @facets_constraints = facets_constraints
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

      "#{CloudSearch.config.search_url}/search".tap do |u|
        u.concat("?q=#{query}&size=#{items_per_page}&start=#{start}")
        u.concat("&bq=#{boolean_query}") if @boolean_queries.any?
        u.concat("&return-fields=#{URI.escape(@fields.join(","))}") if @fields.any?
        u.concat("&#{filter_expression}") if @filters.any?
        u.concat("&facet=#{@facets.join(',')}") if @facets.any?
        u.concat(@facets_constraints.map do |k,v|
          values = v.respond_to?(:map) ? v.map{ |i| "'#{i}'" } : ["'#{v}'"]
          "&facet-#{k}-constraints=#{values.join(',')}"
        end.join('&'))
        u.concat("&rank=#{@rank}") if @rank
      end
    end

    def query
      CGI::escape(@query)
    end

    def boolean_query
      bq = @boolean_queries.map do |key, values|
        "#{key}:'#{values.map { |e| CGI::escape(e) }.join('|')}'"
      end.join(' ')
      "(and #{bq})"
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

    def filter_expression
      @filters.join("&")
    end
  end
end

