class OrderStatus < ApplicationRecord
  acts_as_list scope: :user

  belongs_to :user
  belongs_to :order_status_group, optional: true
  has_many :orders, foreign_key: :status_id

  validates :full_name, presence: true
  validates :short_name, presence: true
  validate :only_one_default_per_user

  before_destroy :prevent_destroy_if_default, :prevent_destroy_if_order_exists

  scope :default, -> { where(default: true) }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[id full_name short_name]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[orders user order_status_group]
  end

  private

  def prevent_destroy_if_order_exists
    if orders.any?
      errors.add(:base, "Nie można usunąć statusu, jeśli znajdują się w nim zamówienia")
      throw :abort
    end
  end

  def only_one_default_per_user
    return unless default?

    existing_default = user.order_statuses.where(default: true)
    existing_default = existing_default.where.not(id: id) if persisted?

    if existing_default.exists?
      errors.add(:default, "może być tylko jeden domyślny status na użytkownika")
    end
  end

  def prevent_destroy_if_default
    if default?
      errors.add(:base, "Nie można usunąć domyślnego statusu")
      throw :abort
    end
  end
end
