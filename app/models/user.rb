class User < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_many :catalogs, dependent: :destroy
  has_many :warehouses, dependent: :destroy
  has_many :price_groups, dependent: :destroy
  has_many :order_statuses, dependent: :destroy
  has_many :order_status_groups, dependent: :destroy
  has_many :invoicing_integrations, dependent: :destroy
  has_many :invoices, dependent: :destroy


  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 2 }
  validates :password_confirmation, presence: true, length: { minimum: 2 }

  after_create :create_default_data


  private

  def create_default_data
    # Catalogs, warehouses and price groups
    catalogs.create!(name: "Domyślny", default: true, user: self)
    warehouses.create!(name: "Domyślny", default: true, user: self)
    price_groups.create!(name: "Podstawowa", default: true, user: self)

    # Connect default catalog with default warehouses and price groups
    catalogs.first.warehouses << warehouses.first
    catalogs.first.price_groups << price_groups.first

    # Order statuses
    order_statuses.create!(full_name: "Nowe", short_name: "Nowe", user: self)
    order_statuses.create!(full_name: "W realizacji", short_name: "W realizacji", user: self)
    order_statuses.create!(full_name: "Wysłane", short_name: "Wysłane", user: self)
    order_statuses.create!(full_name: "Zakończone", short_name: "Zakończone", user: self)
  end
end
