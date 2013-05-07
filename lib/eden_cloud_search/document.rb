module CloudSearch
  class Document
    MAX_VERSION = 4294967295

    attr_accessor :type, :lang, :fields
    attr_reader :errors, :id, :version

    def initialize(attributes = {})
      attributes.each_pair { |key, value| self.__send__("#{key}=", value) }
    end

    def id=(_id)
      @id = _id.to_s
    end

    def version=(_version)
      begin
        @version = Integer(_version)
      rescue ArgumentError, TypeError
        @version = _version
      end
    end

    def valid?
      @errors = {}
      run_id_validations
      run_version_validations
      run_type_validations
      if type == "add"
        run_lang_validations
        run_fields_validations
      end
      errors.empty?
    end

    def as_json
      {:type => type, :id => id, :version => version}.tap do |hash|
        hash.merge!(:lang => lang, :fields => fields) if type == "add"
      end
    end

    def to_json
      JSON.unparse as_json
    end

    private

    def run_id_validations
      validate :id do |messages|
        messages << "can't be blank" if blank?(:id)
        messages << "is invalid" unless blank?(:id) or id =~ /\A[^_][a-z0-9_]+\z/
      end
    end

    def run_version_validations
      validate :version do |messages|
        messages << "can't be blank" if blank?(:version)
        messages << "is invalid" unless blank?(:version) or version.to_s =~ /\A[0-9]+\z/
        messages << "must be less than #{MAX_VERSION + 1}" if messages.empty? and version > MAX_VERSION
      end
    end

    def run_type_validations
      validate :type do |messages|
        messages << "can't be blank" if blank?(:type)
        messages << "is invalid" if !blank?(:type) and !%w(add delete).include?(type)
      end
    end

    def run_lang_validations
      validate :lang do |messages|
        messages << "can't be blank" if blank?(:lang)
        messages << "is invalid" unless blank?(:lang) or lang =~ /\A[a-z]{2}\z/
      end
    end

    def run_fields_validations
      validate :fields do |messages|
        messages << "can't be empty" if fields.nil?
        messages << "must be an instance of Hash" if !fields.nil? and !fields.instance_of?(Hash)
      end
    end

    def blank?(attr)
      self.__send__(attr).to_s.strip.length.zero?
    end

    def validate(attr, &block)
      messages = []
      yield messages
      errors[attr] = messages unless messages.empty?
    end
  end
end

