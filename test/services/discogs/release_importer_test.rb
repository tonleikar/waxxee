require "test_helper"

class Discogs::ReleaseImporterTest < ActiveSupport::TestCase
  class FakeClient
    def initialize(payload)
      @payload = payload
    end

    def find_release(_release_id)
      @payload
    end
  end

  test "imports a discogs release into a vinyl record" do
    payload = {
      "id" => 42,
      "title" => "Discovery",
      "uri" => "https://www.discogs.com/release/42-Daft-Punk-Discovery",
      "year" => 2001,
      "artists" => [{ "name" => "Daft Punk" }],
      "genres" => ["Electronic"],
      "formats" => [{ "name" => "Vinyl" }],
      "tracklist" => [{ "title" => "One More Time" }, { "title" => "Aerodynamic" }],
      "images" => [{ "type" => "primary", "uri" => "https://img.example/discovery.jpg" }]
    }

    importer = Discogs::ReleaseImporter.new(client: FakeClient.new(payload))

    vinyl = importer.import!(release_id: 42)

    assert_equal "Discovery", vinyl.title
    assert_equal "Daft Punk", vinyl.artist
    assert_equal 2001, vinyl.year
    assert_equal "Vinyl", vinyl.format
    assert_equal "Electronic", vinyl.genre
    assert_equal ["One More Time", "Aerodynamic"], vinyl.tracks
    assert_equal "https://img.example/discovery.jpg", vinyl.artwork_url
    assert_equal "https://www.discogs.com/release/42-Daft-Punk-Discovery", vinyl.discogs_url
    assert vinyl.persisted?
  end

  test "uses swiper cover image when discogs release has no primary image" do
    payload = {
      "title" => "Discovery",
      "year" => 2001,
      "artists" => [{ "name" => "Daft Punk" }],
      "genres" => ["Electronic"],
      "formats" => [{ "name" => "Vinyl" }],
      "tracklist" => [{ "title" => "One More Time" }],
      "thumb" => "https://img.example/discovery-thumb.jpg"
    }

    importer = Discogs::ReleaseImporter.new(client: FakeClient.new(payload))

    vinyl = importer.import!(
      release_id: 42,
      cover_image: "https://img.example/discovery-cover.jpg"
    )

    assert_equal "https://img.example/discovery-cover.jpg", vinyl.artwork_url
  end

  test "falls back to generated Discogs release URL when uri is missing" do
    payload = {
      "id" => 42,
      "title" => "Discovery",
      "year" => 2001,
      "artists" => [{ "name" => "Daft Punk" }],
      "genres" => ["Electronic"],
      "formats" => [{ "name" => "Vinyl" }],
      "tracklist" => [{ "title" => "One More Time" }]
    }

    importer = Discogs::ReleaseImporter.new(client: FakeClient.new(payload))

    vinyl = importer.import!(release_id: 42)

    assert_equal "https://www.discogs.com/release/42", vinyl.discogs_url
  end
end
