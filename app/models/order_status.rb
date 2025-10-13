class OrderStatus < ApplicationRecord
  acts_as_list scope: :user

  belongs_to :user
  has_many :orders, foreign_key: :status_id

  validates :full_name, presence: true
  validates :short_name, presence: true

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[id full_name short_name]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[orders user]
  end
end
