class Tag < ApplicationRecord
  acts_as_list scope: :account

  def self.ransackable_attributes(auth_object = nil)
    %w[id name]
  end

  SCOPES = {
    "Zamówienia" => "orders",
    "Produkty" => "products"
  }.freeze

  belongs_to :account
  has_many :taggings, dependent: :destroy
  has_many :orders, through: :taggings, source: :taggable, source_type: "Order"
  has_many :products, through: :taggings, source: :taggable, source_type: "Product"

  after_save :cleanup_orphaned_taggings

  def scopes
    super || []
  end

  def scopes=(value)
    super(Array(value).reject(&:blank?))
  end

  def scope_names
    scopes.map { |s| SCOPES.key(s) }.compact
  end

  private

  def cleanup_orphaned_taggings
    return unless saved_change_to_scopes?

    taggings.where(taggable_type: "Order").destroy_all unless scopes.include?("orders")
    taggings.where(taggable_type: "Product").destroy_all unless scopes.include?("products")
  end
end
