class Catalog < ApplicationRecord
  belongs_to :user

  has_and_belongs_to_many :warehouses
  has_and_belongs_to_many :price_groups
  has_many :products, dependent: :destroy

  validates :name, presence: true
  validates :user_id, presence: true

  before_save :ensure_default_catalog
  before_destroy :prevent_destroy_if_default

  private

  def ensure_default_catalog
    if default?
      Catalog.where(default: true).where.not(id: self.id).update_all(default: false)
    end
  end

  def prevent_destroy_if_default
    if default?
      errors.add(:base, "Nie można usunąć domyślnego katalogu")
      throw :abort
    end
  end
end
