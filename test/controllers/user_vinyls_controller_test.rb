require "test_helper"

class UserVinylsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "collector@example.com",
      username: "collector",
      password: "password123",
      password_confirmation: "password123"
    )
    @vinyl = Vinyl.create!(title: "Future Days", artist: "Can", year: 1973, genre: "Rock")

    sign_in @user
  end

  test "saving a record refreshes the primary persona" do
    updater = Minitest::Mock.new
    updater.expect(:call, true)

    PersonaUpdater.stub(:new, updater) do
      assert_difference("UserVinyl.count", 1) do
        post user_vinyls_path, params: { user_vinyl: { vinyl_id: @vinyl.id } }, as: :json
      end
    end

    assert_response :created
    updater.verify
  end

  test "duplicate save does not create a second user vinyl" do
    UserVinyl.create!(user: @user, vinyl: @vinyl)

    PersonaUpdater.stub(:new, ->(*_args, **_kwargs) { flunk "persona updater should not run" }) do
      assert_no_difference("UserVinyl.count") do
        post user_vinyls_path, params: { user_vinyl: { vinyl_id: @vinyl.id } }, as: :json
      end
    end

    assert_response :created
  end
end
