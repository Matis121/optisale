class CatalogsPriceGroup < ApplicationRecord
  belongs_to :catalog
  belongs_to :price_group
end
