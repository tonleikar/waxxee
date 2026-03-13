class Vinyl < ApplicationRecord
  has_many :user_vinyls, dependent: :destroy
  has_many :users, through: :user_vinyls
  has_many :folders, through: :user_vinyls

  def year_known?
    year.to_i.positive?
  end

  def display_year
    year if year_known?
  end
end
