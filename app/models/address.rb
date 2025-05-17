class Address < ApplicationRecord
  belongs_to :order

  enum :kind, { delivery: 0, invoice: 1 }

  validates :kind, presence: true
end
