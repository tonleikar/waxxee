require "test_helper"

class FollowersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @follower = User.create!(
      email: "follower@example.com",
      username: "follower",
      password: "password123",
      password_confirmation: "password123"
    )
    @followed = User.create!(
      email: "followed@example.com",
      username: "followed",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in @follower
  end

  test "creates a follow relationship" do
    assert_difference("Follower.count", 1) do
      post followers_path, params: { followed_id: @followed.id }
    end

    assert_redirected_to users_path
    assert_equal @followed, Follower.order(:created_at).last.followed
  end

  test "destroys a follow relationship" do
    follow = Follower.create!(follower: @follower, followed: @followed)

    assert_difference("Follower.count", -1) do
      delete follower_path(follow)
    end

    assert_redirected_to users_path
  end

  test "feed only shows followed users" do
    unfollowed_user = User.create!(
      email: "not-followed@example.com",
      username: "notfollowed",
      password: "password123",
      password_confirmation: "password123"
    )
    followed_vinyl = Vinyl.create!(title: "Discovery", artist: "Daft Punk", year: 2001, genre: "Electronic")
    unfollowed_vinyl = Vinyl.create!(title: "Dummy", artist: "Test Artist", year: 1999, genre: "Rock")
    Follower.create!(follower: @follower, followed: @followed)
    UserVinyl.create!(user: @followed, vinyl: followed_vinyl)
    UserVinyl.create!(user: unfollowed_user, vinyl: unfollowed_vinyl)

    get feed_index_path

    assert_response :success
    assert_includes response.body, @followed.username
    assert_not_includes response.body, unfollowed_user.username
    assert_includes response.body, followed_vinyl.title
    assert_not_includes response.body, unfollowed_vinyl.title
  end
end
