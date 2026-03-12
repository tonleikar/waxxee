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

  test "filters swiper vinyls by generated persona rules" do
    matching = Vinyl.create!(
      title: "Cosmic Journey",
      artist: "Band",
      year: 1978,
      genre: "Jazz Fusion",
      artwork_url: "https://example.com/cosmic.jpg"
    )

    Vinyl.create!(
      title: "Outside Window",
      artist: "Band",
      year: 1998,
      genre: "Jazz Fusion",
      artwork_url: "https://example.com/late.jpg"
    )

    persona = @user.personas.create!(
      title: "Fusion Explorer",
      summary: "A fusion-heavy record lane.",
      min_year: 1970,
      max_year: 1985,
      genres: ["Jazz"],
      keywords: ["fusion"]
    )

    get swiper_index_url(persona_id: persona.id)

    assert_response :success
    assert_includes response.body, matching.title
    assert_not_includes response.body, "Outside Window"
    assert_includes response.body, persona.title
  end
end
