class Order < ApplicationRecord
  belongs_to :user
  belongs_to :order_status, foreign_key: :status_id
end
