require 'open-uri'
require 'JSON'

url = "https://api.discogs.com/users/samsamhailey/collection/folders/0/releases?page=1&per_page=100"

# user = User.find_or_create_by!(email: "paul@thebeatles.com") do |u|
#   u.password = "password123"
#   u.password_confirmation = "password123"
# end

response = URI.open(url).read
data = JSON.parse(response)

data["releases"].each do |line|
  p line["basic_information"]["genres"].join(" / ")
end
