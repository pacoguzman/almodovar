module Almodovar
  class HttpError < StandardError
    attr_reader :response_status, :response_body

    # Children of this class must not override the initialize method
    def initialize(response, url)
      @response_status = response.status
      @response_body = response.body
      super("Status code #{response.status} on resource #{url}")
    end
  end

  class TimeoutError < StandardError
  end

  class SendTimeoutError < TimeoutError
  end

  class ReceiveTimeoutError < TimeoutError
  end

  class ConnectTimeoutError < TimeoutError
  end

  class UnprocessableEntityError < HttpError
    def errors?
      error_messages.any?
    end

    # There are some different kind of errors in Almodovar servers
    # "errors" => [{"error" => "wadus"}]
    # "errors" => {"error" => ["wadus", "foo"]
    # "error" => {"message" => "chaflan"}
    #
    # In case we cannot parse the response an empty array is returned
    def error_messages
      @error_messages ||= begin
        if hash.key?('errors')
          Array.wrap(hash['errors']).flat_map do |error|
            error.is_a?(Hash) && error.key?('error') ? error['error'] : error.to_s
          end
        elsif hash.key?('error')
          Array.wrap(hash['error'] && hash['error']['message'])
        else
          []
        end
      end
    end

    private

    def hash
      @hash ||= begin
        Hash.from_xml(@response_body) || {}
      rescue StandardError
        # The expected errors depends on the ActiveSupport::XmlMini_parser used that it's REXML by default but there
        # are other, so just rescue a generic error
        {}
      end
    end
  end

  HTTP_ERRORS = {
    422 => UnprocessableEntityError
  }
end
