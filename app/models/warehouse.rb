class Warehouse < ApplicationRecord
  belongs_to :account
  has_and_belongs_to_many :catalogs
  has_many :product_stocks, dependent: :destroy
  has_many :stock_movements, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }

  before_save :ensure_default_warehouse
  before_destroy :prevent_destroy, prepend: true

  private

  def ensure_default_warehouse
    if default?
      Warehouse.where(default: true).where.not(id: self.id).update_all(default: false)
    end
  end

  def prevent_destroy
    if default?
      errors.add(:base, "Nie można usunąć domyślnego magazynu")
      throw :abort
    end
  end
end
