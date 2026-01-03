class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :catalogs, dependent: :delete_all
  has_many :products, through: :catalogs
  has_many :warehouses, dependent: :delete_all
  has_many :price_groups, dependent: :delete_all
  has_many :order_statuses, dependent: :delete_all
  has_many :order_status_groups, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :receipts, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  has_many :account_integrations, dependent: :destroy

  validates :name, presence: true
  validates :nip, presence: true, format: { with: /\A\d{10}\z/ }, uniqueness: true

  after_create :create_default_data

  def default_order_status
    order_statuses.default.first || order_statuses.first
  end

  def owner
    users.find_by(role: "owner")
  end

  private

  def create_default_data
    # Catalogs, warehouses and price groups
    catalogs.create!(name: "Domyślny", default: true, account: self)
    warehouses.create!(name: "Domyślny", default: true, account: self)
    price_groups.create!(name: "Podstawowa", default: true, account: self)

    # Connect default catalog with default warehouses and price groups
    catalogs.first.warehouses << warehouses.first
    catalogs.first.price_groups << price_groups.first

    # Order statuses
    order_statuses.create!(full_name: "Nowe", short_name: "Nowe", account: self, default: true)
    order_statuses.create!(full_name: "W realizacji", short_name: "W realizacji", account: self)
    order_statuses.create!(full_name: "Wysłane", short_name: "Wysłane", account: self)
    order_statuses.create!(full_name: "Zakończone", short_name: "Zakończone", account: self)
  end
end
