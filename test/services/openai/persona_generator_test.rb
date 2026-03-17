require "test_helper"

module Openai
  class PersonaGeneratorTest < ActiveSupport::TestCase
    test "normalize_persona falls back when unsplash returns no image" do
      generator = PersonaGenerator.new(user: User.new, prompt: "Build me a persona.")
      payload = {
        "title" => "Cosmic Drift",
        "summary" => "A floating cosmic jazz profile.",
        "min_year" => 1968,
        "max_year" => 1983,
        "genres" => ["Jazz", "Funk / Soul"],
        "keywords" => ["cosmic", "warm"],
        "url" => "https://api.discogs.com/database/search?type=release"
      }

      Unsplash::Photo.stub(:random, nil) do
        persona = generator.send(:normalize_persona, payload)

        assert_equal "Cosmic Drift", persona[:title]
        assert_nil persona[:image_url]
        assert_nil persona[:image_credit]
      end
    end

    test "normalize_persona falls back when unsplash raises" do
      generator = PersonaGenerator.new(user: User.new, prompt: "Build me a persona.")
      payload = {
        "title" => "Cosmic Drift",
        "summary" => "A floating cosmic jazz profile.",
        "min_year" => 1968,
        "max_year" => 1983,
        "genres" => ["Jazz", "Funk / Soul"],
        "keywords" => ["cosmic", "warm"],
        "url" => "https://api.discogs.com/database/search?type=release"
      }

      Unsplash::Photo.stub(:random, ->(**) { raise StandardError, "no image" }) do
        persona = generator.send(:normalize_persona, payload)

        assert_equal "Cosmic Drift", persona[:title]
        assert_nil persona[:image_url]
        assert_nil persona[:image_credit]
      end
    end
  end
end
