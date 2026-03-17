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

premade = [ {
  title: "uk garage",
  summary: "ukg's signature blend of shuffling beats, soulful vocals, and bass-heavy grooves from the late 90s and early 2000s.",
  min_year: 1988,
  max_year: 1999,
  genres: ["Electronic", "Dance", "UK Garage"],
  image_url: "staff-picks/ukg-persona.jpg",
  url: "https://api.discogs.com/database/search?style=UK+Garage&type=releaseyear=1996-2022"
},
{
  title: "afrobeat",
  summary: "Rhythmic grooves, vibrant percussion, and infectious energy from the heart of Afrobeat and its global offshoots.",
  min_year: 1970,
  max_year: 1989,
  genres: ["Funk", "Soul", "Afrobeat"],
  image_url: "staff-picks/afrobeat-persona.jpg",
  url: "https://api.discogs.com/database/search?style=Afrobeat&genre=Funk+/+Soul&type=releaseyear=1970-1989"
},
{
  title: "post-punk",
  summary: "Dark, angular, and experimental sounds that defined the post-punk era, blending punk's raw energy with art-rock's creativity.",
  min_year: 1979,
  max_year: 1987,
  genres: ["Post-Punk", "New Wave", "Electronic"],
  image_url: "staff-picks/punk-persona.jpg",
  url: "https://api.discogs.com/database/search?style=Post-Punk&genre=Rock&type=releaseyear=1979-1987"
},

{
  title: "jazz",
  summary: "Soulful vocals, lush arrangements, and timeless songwriting across classic and contemporary jazz records.",
  min_year: 1950,
  max_year: 1978,
  genres: ["Jazz"],
  image_url: "staff-picks/jazz-persona.jpg",
  url: "https://api.discogs.com/database/search?genre=Jazz&year=1950-1978&type=release"
}]

premade.each do |premade|
  p premade
  new_persona = Persona.create(
    title: premade[:title],
    summary: premade[:summary],
    min_year: premade[:min_year],
    max_year: premade[:max_year],
    image_url: premade[:image_url],
    url: premade[:url],
    genres: premade[:genres],
    keywords: premade[:genres],
    staff_pick: true
  )
  new_persona.save!
end
