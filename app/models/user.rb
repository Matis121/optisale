class User < ApplicationRecord
  belongs_to :account, optional: true

  attr_accessor :account_name, :account_nip

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         password_length: 12..64

  validates :role, presence: true, inclusion: { in: %w[owner employee] }
  validates :account_id, presence: true, unless: -> { new_record? && owner? }

  validate :account_must_be_valid

  before_validation :build_account_from_attributes, on: :create, if: :owner?
  before_destroy :prevent_destroy_if_owner

  def owner?
    role == "owner"
  end

  def employee?
    role == "employee"
  end

  def default_order_status
    account&.default_order_status
  end

  private

  def account_must_be_valid
    return unless account
    return if account.valid?

    account.errors.each do |error|
      # Przenosimy błędy z account do odpowiednich pól w user
      case error.attribute
      when :name
        errors.add(:account_name, error.message)
      when :nip
        errors.add(:account_nip, error.message)
      else
        errors.add(:base, error.full_message)
      end
    end
  end

  def prevent_destroy_if_owner
    if owner?
      errors.add(:base, "Nie można usunąć właściciela.")
      throw :abort
    end
  end

  def build_account_from_attributes
    self.account = Account.new(name: account_name, nip: account_nip)
  end
end
