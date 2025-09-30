module Integrations
  class BaseAdapter
    attr_reader :integration

    def initialize(integration)
      @integration = integration
    end

    # Interface to implement in specific adapters

    # Connection test - returns true/false
    def test_connection
      raise NotImplementedError, "Subclass must implement test_connection"
    end

    protected

    # Helper methods available for all adapters

    def credentials
      integration.credentials
    end

    def configuration
      integration.configuration
    end

    def http_client
      @http_client ||= HTTP.timeout(30)
    end

    # Logs errors with context
    def log_error(message, error = nil)
      Rails.logger.error "[#{self.class.name}] #{message}"
      Rails.logger.error "[#{self.class.name}] Error: #{error.message}" if error
      Rails.logger.error "[#{self.class.name}] Backtrace: #{error.backtrace.join("\n")}" if error&.backtrace
    end
  end
end
