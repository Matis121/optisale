class InvoicingIntegration < Integration
  # Specific associations for fakturownia
  has_many :invoices, dependent: :destroy

  # Specific validations for fakturownia
  validates :provider, inclusion: { in: %w[fakturownia] }

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
    required = self.class.required_credentials_for(provider)
    missing = required - credentials.keys.map(&:to_s)

    if missing.any?
      errors.add(:credentials, "missing required fields: #{missing.join(', ')}")
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
