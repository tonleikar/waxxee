require "test_helper"

class SwiperControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "swiper@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in @user
  end

  test "filters swiper vinyls by persona rules" do
    matching = Vinyl.create!(
      title: "Dream Pop Record",
      artist: "Band",
      year: 2002,
      genre: "Pop",
      artwork_url: "https://example.com/pop.jpg"
    )

    Vinyl.create!(
      title: "Wrong Genre",
      artist: "Band",
      year: 2002,
      genre: "Jazz",
      artwork_url: "https://example.com/jazz.jpg"
    )

    Vinyl.create!(
      title: "Wrong Year",
      artist: "Band",
      year: 1975,
      genre: "Pop",
      artwork_url: "https://example.com/old.jpg"
    )

    get swiper_index_url(persona: "emo")

    assert_response :success
    assert_includes response.body, matching.title
    assert_not_includes response.body, "Wrong Genre"
    assert_not_includes response.body, "Wrong Year"
  end
end
