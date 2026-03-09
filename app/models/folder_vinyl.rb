class FolderVinyl < ApplicationRecord
  belongs_to :folder
  belongs_to :user_vinyl
end
