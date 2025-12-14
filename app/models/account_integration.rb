class AccountIntegration < ApplicationRecord
  encrypts :credentials
  serialize :credentials, coder: JSON

  belongs_to :account
  belongs_to :integration

  enum :status, { active: "active", inactive: "inactive" }

  validates :account, presence: true
  validates :integration, presence: true
  validates :name, presence: true
  validates :status, presence: true
  validate :check_multiple_allowed, on: :create

  def settings
    super || {}
  end

  def settings=(value)
    super(value)
  end

  def adapter
    adapter_class.new(self)
  end

  def test_connection!
    adapter.test_connection
    update_columns(status: :active, error_message: nil)
    true
  rescue => e
    update_columns(status: :inactive, error_message: e.message)
    false
  end

  private

  def check_multiple_allowed
    if !integration.multiple_allowed? && account.account_integrations.where(integration: integration).exists?
      errors.add(:base, "Limit dla integracji został osiągnięty")
    end
  end

  def adapter_class
    case integration.key
    when "fakturownia"
      Integrations::Invoicing::FakturowniaAdapter
    else
      raise "Unknown integration: #{integration.key}"
    end
  end
end
