class OrderStatus < ApplicationRecord
  belongs_to :user
  has_many :orders, foreign_key: :status_id

  validates :full_name, presence: true
  validates :short_name, presence: true
end
