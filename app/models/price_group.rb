class PriceGroup < ApplicationRecord
  belongs_to :account
  has_and_belongs_to_many :catalogs
  has_many :product_prices, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }


  before_save :ensure_default_price_group
  before_destroy :prevent_destroy_if_default

  private

  def ensure_default_price_group
    if default?
      PriceGroup.where(default: true).where.not(id: self.id).update_all(default: false)
    end
  end

  def prevent_destroy_if_default
    if default?
      errors.add(:base, "Nie można usunąć domyślnej grupy cenowej")
      throw :abort
    end
  end
end
