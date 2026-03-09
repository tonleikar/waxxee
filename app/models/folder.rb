class Folder < ApplicationRecord
  belongs_to :user
  has_many :folder_vinyls, dependent: :destroy
  has_many :user_vinyls, through: :folder_vinyls
  has_many :vinyls, through: :user_vinyls
end
