class CatalogsWarehouse < ApplicationRecord
  belongs_to :catalog
  belongs_to :warehouse
end
