class Catalog < ApplicationRecord
  belongs_to :user

  has_and_belongs_to_many :warehouses
  has_and_belongs_to_many :price_groups
  has_many :products, dependent: :destroy

  validates :name, presence: true
  validates :user_id, presence: true
end
