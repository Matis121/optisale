class Product < ApplicationRecord
  belongs_to :user
  has_many :order_products

  validates :name, presence: true
end
