class Folder < ApplicationRecord
  belongs_to :user
  has_many :folder_vinyls
  has_many :vinyls, through: :folder_vinyls
end
