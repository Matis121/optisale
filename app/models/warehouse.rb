class Warehouse < ApplicationRecord
  belongs_to :catalog
  has_many :product_stocks, dependent: :destroy

  validates :name, presence: true
  validates :catalog_id, presence: true

  before_save :ensure_default_warehouse
  before_destroy :prevent_destroy_if_default

  private

  def ensure_default_warehouse
    if default?
      self.catalog.warehouses
        .where(default: true)
        .where.not(id: self.id)
        .update_all(default: false)
    end
  end

  def prevent_destroy_if_default
    if default?
      errors.add(:base, "Nie można usunąć domyślnego magazynu")
      throw :abort
    end
  end
end
