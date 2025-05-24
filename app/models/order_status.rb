class OrderStatus < ApplicationRecord
  belongs_to :user
  has_many :orders, foreign_key: :status_id
end
