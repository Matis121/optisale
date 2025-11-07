class OrderStatusGroup < ApplicationRecord
  acts_as_list scope: :account

  belongs_to :account
  has_many :order_statuses, dependent: :nullify

  validates :name, presence: true

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[id name]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order_statuses user]
  end
end
