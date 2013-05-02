require 'uri'

module CloudSearch
  class Searcher
    include ::CloudSearch::ConfigurationChecking

    attr_reader :weights

    def initialize
      @response = SearchResponse.new
      @filters  = []
      @facets   = []
      @fields   = []
      @facets_constraints = {}
    end

    def search
      cloud_search_response = RestClient.get url
      @response.http_code   = cloud_search_response.code
      @response.body        = cloud_search_response.body

      @response
    end

    def with_query(query)
      @query = query
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

    def as_boolean_query
      @boolean = true
      self
    end

    def ranked_by(rank_expression)
      @rank = rank_expression
      self
    end

    def query
      return '' unless @query
      URI.escape(@query).gsub('&', '%26')
    end

    def boolean_query?
      !!@boolean
    end

    def with_fields(*fields)
      @fields += fields
      self
    end

    def with_items_per_page(items_per_page)
      @response.items_per_page = items_per_page
      self
    end

    def items_per_page
      @response.items_per_page
    end

    def at_page(page)
      @page_number = (page && page < 1) ? 1 : page
      self
    end

    def page_number
      @page_number or 1
    end

    def start
      return 0 if page_number <= 1
      (items_per_page * (page_number - 1))
    end

    def url
      check_configuration_parameters

      query_params = {
        query_parameter => query,
        :size           => items_per_page.to_s,
        :start          => start.to_s,
        'return-fields' => URI.escape(@fields.join(',')),
        :facet          => @facets.join(','),
        :rank           => @rank,
      }.merge(@facets_constraints.map do
          |facet, values| { "facet-#{facet}-constraints" => values.join(',') }
        end.reduce({}, :merge))

      "#{CloudSearch.config.search_url}/search?#{as_querystring(query_params)}#{filter_expression}"
    end

    private

    def as_querystring(params)
      compact(params).map { |parameter, value| "#{parameter}=#{value}"}.join('&')
    end

    def compact(params)
      params.delete_if { |parameter, value| parameter != query_parameter && (value.nil? || value.empty?) }
    end

    def query_parameter
      boolean_query? ? "bq" : "q"
    end

    def filter_expression
      @filters.any? ? "&#{@filters.join("&")}" : ""
    end
  end
end
