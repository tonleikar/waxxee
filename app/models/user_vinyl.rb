class UserVinyl < ApplicationRecord
  belongs_to :user
  belongs_to :vinyl
  has_many :folder_vinyls, dependent: :destroy
  has_many :folders, through: :folder_vinyls
end
