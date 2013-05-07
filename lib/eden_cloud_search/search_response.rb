module CloudSearch
  class SearchResponse
    attr_writer   :items_per_page
    attr_reader   :current_page, :total_pages, :body, :facets
    attr_accessor :http_code

    def body=(body)
      @body = JSON.parse(body || "{}")
      calculate_pages
      build_facets
      @body
    end

    def results
      _hits["hit"] || []
    end

    def hits
      _hits["found"] || 0
    end

    def found?
      hits > 0
    end

    def items_per_page
      @items_per_page || 10
    end

    def has_pagination?
      hits > items_per_page
    end

    def offset
      return 0 unless found?
      (@current_page - 1) * items_per_page
    end

    alias :page_size :items_per_page
    alias :limit_value :items_per_page
    alias :total_entries :hits
    alias :any? :found?

    private

    def calculate_pages
      num_full_pages = hits / items_per_page
      @total_pages   = hits % items_per_page > 0 ? num_full_pages + 1 : num_full_pages
      @total_pages   = 1 if @total_pages == 0

      start = _hits["start"] || 0
      @current_page = (start / items_per_page) + 1
      @current_page = @total_pages if @current_page > @total_pages
    end

    def build_facets
      @facets = {}
      return unless body['facets']

      body['facets'].each do |facet, result|
        @facets[facet] = if result['constraints']
          result['constraints'].inject({}) { |hash, item| hash[item['value']] = item['count']; hash }
        else
          result
        end
      end
    end

    def _hits
      body["hits"] || {}
    end
  end
end
