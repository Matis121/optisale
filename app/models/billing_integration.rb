class BillingIntegration < ApplicationRecord
  belongs_to :user
  has_many :invoices, dependent: :destroy

  enum :status, { inactive: "inactive", active: "active", error: "error" }

  validates :provider, presence: true, inclusion: { in: %w[fakturownia] }
  validates :name, presence: true
  validates :provider, uniqueness: { scope: :user_id, message: "integration already exists for this user" }

  scope :active_integrations, -> { where(active: true, status: "active") }
  scope :for_provider, ->(provider) { where(provider: provider) }

  # Deserializuje credentials z JSON
  def credentials
    return {} if encrypted_credentials.blank?

    begin
      # Ensure we have a valid JSON string
      json_string = encrypted_credentials.is_a?(String) ? encrypted_credentials : "{}"
      parsed = JSON.parse(json_string)

      # Ensure we return a Hash, not a String
      return {} unless parsed.is_a?(Hash)

      parsed.with_indifferent_access
    rescue JSON::ParserError
      {}
    end
  end

  # Serializuje credentials do JSON
  def credentials=(value)
    return if value.nil?

    if value.is_a?(Hash)
      # Convert HashWithIndifferentAccess to regular Hash
      begin
        hash_value = value.is_a?(ActiveSupport::HashWithIndifferentAccess) ? value.to_hash : value
        self.encrypted_credentials = hash_value.to_json
      rescue
        self.encrypted_credentials = "{}"
      end
    elsif value.is_a?(String)
      # Validate that it's valid JSON
      begin
        JSON.parse(value)
        self.encrypted_credentials = value
      rescue JSON::ParserError
        self.encrypted_credentials = "{}"
      end
    else
      self.encrypted_credentials = "{}"
    end
  end

  # Deserializuje configuration z JSON
  def configuration
    return {} if super.blank?

    begin
      JSON.parse(super).with_indifferent_access
    rescue JSON::ParserError
      {}
    end
  end

  # Serializuje configuration do JSON
  def configuration=(value)
    super(value.to_json) if value.present?
  end

  # Zwraca adapter dla tego providera
  def adapter
    @adapter ||= case provider
    when "fakturownia"
                   Billing::FakturowniaAdapter.new(self)
    else
                   raise "Unsupported provider: #{provider}"
    end
  end

  # Test connection and automatic activation on success
  def test_connection
    adapter.test_connection

    # Deactivate other integrations of the same provider for this user
    user.billing_integrations
        .where(provider: provider)
        .where.not(id: id)
        .update_all(active: false)

    # Activate this integration
    update!(status: "active", active: true, error_message: nil, last_sync_at: Time.current)
    true
  rescue => e
    update!(status: "error", active: false, error_message: e.message)
    false
  end

  # Checks if integration is ready to use
  def ready?
    active? && status == "active"
  end

  # Returns required credentials for given provider
  def self.required_credentials_for(provider)
    case provider
    when "fakturownia"
      %w[api_token account]
    else
      []
    end
  end

  # Validates that all required credentials are present
  def validate_required_credentials
    required = self.class.required_credentials_for(provider)
    missing = required - credentials.keys.map(&:to_s)

    if missing.any?
      errors.add(:credentials, "missing required fields: #{missing.join(', ')}")
    end
  end

  private

  # TODO: In production, consider implementing proper encryption (Rails credentials or external vault))
end
