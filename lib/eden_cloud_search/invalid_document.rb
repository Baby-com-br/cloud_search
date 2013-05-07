module CloudSearch
  class InvalidDocument < StandardError
    def initialize(document)
      document.valid?
      error_message = document.errors.map do
        |attribute, errors| errors.empty? ? nil : "#{attribute}: #{errors.join(", ")}"
      end.join("; ")
      super error_message
    end
  end
end
