class User < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_many :catalogs, dependent: :destroy
  has_many :warehouses, dependent: :destroy
  has_many :price_groups, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 2 }
  validates :password_confirmation, presence: true, length: { minimum: 2 }

  after_create :create_default_data


  private

  def create_default_data
    default_catalog = catalogs.create!(name: "Domyślny")
    default_catalog.warehouses.create!(name: "Domyślny", default: true)
    default_catalog.price_groups.create!(name: "Podstawowa", default: true)
  end
end
