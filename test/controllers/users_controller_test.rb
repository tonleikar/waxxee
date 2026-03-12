require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = User.create!(
      email: "current@example.com",
      username: "currentuser",
      password: "password123",
      password_confirmation: "password123"
    )
    @matching_user = User.create!(
      email: "joan@example.com",
      username: "joan",
      password: "password123",
      password_confirmation: "password123"
    )
    @other_user = User.create!(
      email: "mia@example.com",
      username: "mia",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in @current_user
  end

  test "shows all other users by default" do
    get users_path

    assert_response :success
    assert_includes response.body, @matching_user.username
    assert_includes response.body, @other_user.username
    assert_not_includes response.body, @current_user.username
  end

  test "filters users by search query" do
    get users_path, params: { query: "joa" }

    assert_response :success
    assert_includes response.body, @matching_user.username
    assert_not_includes response.body, @other_user.username
  end
end
