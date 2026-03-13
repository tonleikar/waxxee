require "test_helper"

class UserVinylsControllerTest < ActionDispatch::IntegrationTest
  class FakeImporter
    def initialize(vinyl)
      @vinyl = vinyl
    end

    def import!(release_id:)
      raise "unexpected release_id" unless release_id.to_s == "42"

      @vinyl
    end
  end

  class FakeUpdater
    attr_reader :call_count

    def initialize
      @call_count = 0
    end

    def call
      @call_count += 1
      true
    end
  end

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
    updater = FakeUpdater.new
    importer = FakeImporter.new(@vinyl)

    with_stubbed_constructor(Discogs::ReleaseImporter, importer) do
      with_stubbed_constructor(PersonaUpdater, updater) do
        assert_difference("UserVinyl.count", 1) do
          post user_vinyls_path, params: { release_id: 42 }, as: :json
        end
      end
    end

    assert_response :created
    assert_equal 1, updater.call_count
  end

  test "duplicate save does not create a second user vinyl" do
    UserVinyl.create!(user: @user, vinyl: @vinyl)
    importer = FakeImporter.new(@vinyl)

    with_stubbed_constructor(Discogs::ReleaseImporter, importer) do
      with_stubbed_constructor(PersonaUpdater, ->(*_args, **_kwargs) { flunk "persona updater should not run" }) do
        assert_no_difference("UserVinyl.count") do
          post user_vinyls_path, params: { release_id: 42 }, as: :json
        end
      end
    end

    assert_response :created
  end

  private

  def with_stubbed_constructor(klass, replacement)
    singleton = class << klass; self; end
    original = klass.method(:new)

    singleton.define_method(:new) do |*_args, **_kwargs|
      replacement
    end

    yield
  ensure
    singleton.define_method(:new, original)
  end
end
