require "test_helper"

class PersonaTest < ActiveSupport::TestCase
  test "picker_rule normalizes blank genres" do
    persona = Persona.new(title: "Custom", min_year: 1980, max_year: 1990, genres: [])

    assert_equal [""] , persona.picker_rule[:genres]
    assert_equal 1980, persona.picker_rule[:min_year]
    assert_equal 1990, persona.picker_rule[:max_year]
  end
end
