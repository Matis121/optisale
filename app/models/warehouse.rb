class Warehouse < ApplicationRecord
  belongs_to :catalog
  has_many :product_stocks, dependent: :destroy

  validates :name, presence: true
  validates :catalog_id, presence: true
end
