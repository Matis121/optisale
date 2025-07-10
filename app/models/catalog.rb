class Catalog < ApplicationRecord
  belongs_to :user

  has_many :warehouses, dependent: :destroy
  has_many :price_groups, dependent: :destroy
  has_many :products, dependent: :destroy

  validates :name, presence: true
  validates :user_id, presence: true
end
