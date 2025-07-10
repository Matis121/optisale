class User < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_many :catalogs, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
