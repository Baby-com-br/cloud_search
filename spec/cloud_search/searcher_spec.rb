require "spec_helper"

describe CloudSearch::Searcher do
  subject(:searcher) { described_class.new }
  let(:url_prefix) { "#{CloudSearch.config.search_url}/search?" }

  before do
    searcher.with_query('lsdakfusur')
  end

  describe "#with_query" do
    it "returns #{described_class} instance" do
      searcher.with_query("foo").should == searcher
    end

    it "sets the query parameter in the search url" do
      searcher.with_query("foo").url.should include "q=foo"
    end

    it "escapes the search term" do
      searcher.with_query("f&oo").url.should include "q=f%26oo"
    end
  end

  describe "#with_boolean_query" do
    it "return #{described_class} instance" do
      searcher.with_boolean_query(:foo => 'bar').should == searcher
    end

    it "sets the boolean query parameter in the search url" do
      searcher.with_boolean_query(:foo => 'bar').url.should include "bq=(and foo:'bar')"
    end

    it "escapes search terms" do
      searcher.with_boolean_query(:foo => 'ba&r').url.should include "bq=(and foo:'ba%26r')"
    end

    it "sets search terms with multiple acceptable values" do
      searcher.with_boolean_query(:foo => ['bar', 'baz']).url.should include "bq=(and foo:'bar|baz')"
    end

    it "sets multiple search keys" do
      searcher.with_boolean_query(:foo => 'bar', :baz => ['zaz', 'traz']).url.should include "bq=(and foo:'bar' baz:'zaz|traz')"
    end
  end

  describe "#with_facet" do
    it "setup facets" do
      searcher.with_facets("foo", "bar").url.should include "facet=foo,bar"
    end
  end

  describe "#with_facet_constraints" do
    it "setup facets" do
      searcher.with_facet_constraints(:foo => ["bar", "spam"]).url.should include "facet-foo-constraints='bar','spam'"
    end
  end

  describe "#ranked_by" do
    it "returns the instance" do
      searcher.ranked_by("foobar").should == searcher
    end

    it "sets the rank expression in the searcher object" do
      searcher.ranked_by("foobar").url.should include "rank=foobar"
    end
  end

  describe "#with_fields" do
    it "returns #{described_class} instance" do
      searcher.with_fields(:foo).should == searcher
    end

    it "setup more thane one value" do
      searcher.with_fields(:foo, :bar, :foobar)
    end

    it "returns cloud search url with foo and bar fields" do
      searcher.with_fields(:foo, :bar).url.should include "return-fields=foo,bar"
    end
  end

  describe "#items_per_page" do
    it "returns default items_per_page" do
      searcher.items_per_page.should == 10
    end

    it "returns default items per page when it's tried to set nil value" do
      searcher.with_items_per_page(nil)
      searcher.items_per_page.should == 10
    end
  end

  describe "#with_items_per_page" do
    it "returns #{described_class} instance" do
      searcher.with_items_per_page(nil).should == searcher
    end

    it "setup items per page" do
      searcher.with_items_per_page(100)
      searcher.items_per_page.should == 100
    end

    it "returns cloud search url with size equals 20" do
      searcher.with_items_per_page(20).url.should include "size=20"
    end
  end

  describe "#page_number" do
    it "returns default page number" do
      searcher.page_number.should == 1
    end

    it "returns default page number when it's tried to set nil value" do
      searcher.at_page(nil)
      searcher.page_number.should == 1
    end
  end

  describe "#at_page" do
    it "returns #{described_class} instance" do
      searcher.at_page(1).should == searcher
    end

    it "setup page number" do
      searcher.at_page(2)
      searcher.page_number.should == 2
    end

    it "ensure page is greater than 1" do
      searcher.at_page(0)
      searcher.page_number.should == 1

      searcher.at_page(-1)
      searcher.page_number.should == 1
    end

    it "returns cloud search url with start at 10" do
      searcher.at_page(2).url.should include "start=10"
    end
  end

  describe "#with_filter" do
    it "adds the filter to the query" do
      searcher.with_query("foo").with_filter("t-product_active=1")
      searcher.url.should == "#{url_prefix}q=foo&size=10&start=0&t-product_active=1"
    end

    it "can be used to add several filter expressions to the query" do
      searcher.with_query("foo").with_filter("t-product_active=1").with_filter("t-brand_active=1")
      searcher.url.should == "#{url_prefix}q=foo&size=10&start=0&t-product_active=1&t-brand_active=1"
    end
  end

  describe "#start" do
    it "returns default start index number to search" do
      searcher.start.should == 0
    end

    it "returns start index 10 for page 2" do
      searcher.at_page(2)
      searcher.start.should == 10
    end
  end

  describe "#url" do
    it "returns default cloud search url" do
      searcher.url.should include "size=10&start=0"
    end

    it "raises an error if neither query nor boolean query are defined" do
      expect { described_class.new.url }.to raise_error CloudSearch::InsufficientParametersException
    end
  end

  describe "#search" do
    before do
      searcher
      .with_fields(:actor, :director, :title, :year, :text_relevance)
      .with_query("star wars")
    end

    context "when the domain id was not configured" do
      around do |example|
        domain_id = CloudSearch.config.domain_id
        CloudSearch.config.domain_id = nil
        example.call
        CloudSearch.config.domain_id = domain_id
      end

      it "raises an error" do
        expect {
          searcher.search
        }.to raise_error(CloudSearch::MissingConfigurationError, "Missing 'domain_id' configuration parameter")
      end
    end

    context "when the domain name was not configured" do
      around do |example|
        domain_name = CloudSearch.config.domain_name
        CloudSearch.config.domain_name = nil
        example.call
        CloudSearch.config.domain_name = domain_name
      end

      it "raises an error" do
        expect {
          searcher.search
        }.to raise_error(CloudSearch::MissingConfigurationError, "Missing 'domain_name' configuration parameter")
      end
    end

    context "when search" do
      around { |example| VCR.use_cassette "search/request/full", &example }

      it "returns http 200 code" do
        resp = searcher.search
        resp.http_code.should == 200
      end

      it "has found results" do
        resp = searcher.search
        resp.should be_found
      end

      it "returns number of hits" do
        resp = searcher.search
        expect(resp.hits).to be == 7
      end

      it "returns Episode II" do
        resp = searcher.search
        resp.results.map{ |item| item['data']['title'] }.flatten
        .should include "Star Wars: Episode II - Attack of the Clones"
      end

      it "returns facets" do
        VCR.use_cassette "search/request/facets" do
          searcher.with_facets(:genre, :year)
          resp = searcher.search
          resp.facets.should == {"genre"=>{"Action"=>7, "Adventure"=>7, "Sci-Fi"=>7, "Fantasy"=>5, "Animation"=>1, "Family"=>1, "Thriller"=>1}, "year"=>{"min"=>1977, "max"=>2008}}
        end
      end

      it "constrains facets" do
        VCR.use_cassette "search/request/facets_with_constraints" do
          searcher.with_facets(:genre, :year)
          searcher.with_facet_constraints(:genre => "Sci-Fi")
          resp = searcher.search
          resp.facets.should == {"genre"=>{"Sci-Fi"=>7}, "year"=>{"min"=>1977, "max"=>2008}}
        end
      end
    end

    context "when paginate result" do
      it "returns first page" do
        VCR.use_cassette "search/request/paginated_first_page" do
          searcher.with_items_per_page(4)
          searcher.at_page(1)
          resp = searcher.search
          resp.results.map{ |item| item['data']['title'] }.flatten
          .should include "Star Wars: Episode II - Attack of the Clones"
        end
      end

      it "returns second page" do
        VCR.use_cassette "search/request/paginated_second_page" do
          searcher.with_items_per_page(4)
          searcher.at_page(2)
          resp = searcher.search
          resp.results.map{ |item| item['data']['title'] }.flatten
          .should include "Star Wars: Episode III - Revenge of the Sith"
        end
      end
    end
  end
end

