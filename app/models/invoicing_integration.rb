class InvoicingIntegration < Integration
  # Specific associations for fakturownia

  # Specific validations for fakturownia
  validates :provider, inclusion: { in: %w[fakturownia] }
  validate :validate_required_credentials

  # Returns required credentials for given provider (specific for fakturownia)
  def self.required_credentials_for(provider)
    case provider
    when "fakturownia"
      %w[api_token account]
    else
      []
    end
  end

  # Validates that all required credentials are present (specific for fakturownia)
  def validate_required_credentials
    return unless provider.present?

    creds = credentials || {}
    required = self.class.required_credentials_for(provider)

    required.each do |field|
      if creds[field].blank?
        case field
        when "account"
          errors.add(:credentials_account, "nie może być pusta")
        when "api_token"
          errors.add(:credentials_api_token, "nie może być pusty")
        else
          errors.add(:credentials, "#{field} jest wymagany")
        end
      end
    end
  end


  # Specific methods for fakturownia
  def adapter
    @adapter ||= case provider
    when "fakturownia"
      Integrations::Invoicing::FakturowniaAdapter.new(self)
    else
      raise "Unsupported provider: #{provider}"
    end
  end
end
