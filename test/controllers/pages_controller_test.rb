require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "randomizer@example.com",
      username: "randomizer-user",
      password: "password123",
      password_confirmation: "password123"
    )

    @saved_vinyl = Vinyl.create!(
      title: "Saved Record",
      artist: "Collection Artist",
      year: 1984,
      genre: "Electronic"
    )
    @other_vinyl = Vinyl.create!(
      title: "Unsaved Record",
      artist: "Outside Artist",
      year: 1992,
      genre: "Rock"
    )

    UserVinyl.create!(user: @user, vinyl: @saved_vinyl)

    sign_in @user
  end

  test "randomizer json returns a vinyl from the signed in user's collection" do
    get randomizer_path(format: :json)

    assert_response :success

    payload = JSON.parse(response.body)

    assert_equal @saved_vinyl.id, payload["id"]
    assert_equal @saved_vinyl.title, payload["title"]
    assert_not_equal @other_vinyl.id, payload["id"]
  end

  test "randomizer json returns not found when the signed in user has no saved vinyls" do
    UserVinyl.where(user: @user).delete_all

    get randomizer_path(format: :json)

    assert_response :not_found

    payload = JSON.parse(response.body)

    assert_equal "No vinyl found.", payload["error"]
  end
end
