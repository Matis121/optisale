module Integrations
  class BaseAdapter
    attr_reader :account_integration

    def initialize(account_integration)
      @account_integration = account_integration
    end

    protected


    def credentials
      account_integration.credentials || {}
    end

    def settings
      account_integration.settings || {}
    end

    def http_client
      @http_client ||= HTTP.timeout(30)
    end
  end
end
