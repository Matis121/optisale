class User < ApplicationRecord
  belongs_to :account, optional: true

  attr_accessor :account_name, :account_nip

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 12 }, on: :create
  validates :password_confirmation, presence: true, length: { minimum: 12 }, on: :create
  validates :role, presence: true, inclusion: { in: %w[owner employee] }
  validates :account_id, presence: true, unless: -> { new_record? && owner? }

  before_validation :build_account_from_attributes, on: :create, if: :owner?

  def owner?
    role == 'owner'
  end

  def employee?
    role == 'employee'
  end

  def default_order_status
    account&.default_order_status
  end

  private

  def build_account_from_attributes
    self.account = Account.new(name: account_name, nip: account_nip)
  end
end
