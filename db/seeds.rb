# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
require 'open-uri'
require 'JSON'

url = "https://api.discogs.com/users/samsamhailey/collection/folders/0/releases?page=1&per_page=100"

User.find_or_create_by!(email: "paul@thebeatles.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.username = "paul"
end

response = URI.open(url).read
data = JSON.parse(response)

puts "adding records"

data["releases"].each do |line|
  record = Vinyl.new
  record.title = line["basic_information"]["title"]
  record.artist = line["basic_information"]["artists"][0]["name"]
  record.year = line["basic_information"]["year"]
  record.artwork_url = line["basic_information"]["cover_image"]
  record.format = line["basic_information"]["formats"][0]["descriptions"].join(" ")
  record.genre  = line["basic_information"]["genres"].join(" / ")
  record.save
end

puts "records added"

sample_users = [
  { email: "debbie@waxxee.com", username: "debbie" },
  { email: "miles@waxxee.com", username: "miles" },
  { email: "joan@waxxee.com", username: "joan" },
  { email: "prince@waxxee.com", username: "prince" },
  { email: "sade@waxxee.com", username: "sade" },
  { email: "bjork@waxxee.com", username: "bjork" }
]

sample_users.each do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |user|
    user.password = "password123"
    user.password_confirmation = "password123"
    user.username = attrs[:username]
  end
end

User.find_each do |user|
  Vinyl.order("RANDOM()").limit(3).each do |vinyl|
    UserVinyl.find_or_create_by!(user: user, vinyl: vinyl)
  end
end
