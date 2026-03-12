require "test_helper"

class PersonasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "persona-owner@example.com",
      username: "personaowner",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in @user
  end

  test "creates or updates the primary persona" do
    updater = ->(*_args, **_kwargs) do
      Struct.new(:call).new(
        Persona.new(
          user: @user,
          title: "Night Digger",
          summary: "A moody late-night crate-digging profile.",
          min_year: 1972,
          max_year: 1994,
          genres: ["Jazz", "Electronic"],
          keywords: ["nocturnal", "deep cuts"],
          primary_profile: true,
          llm_model: "gpt-test"
        ).tap(&:save!)
      )
    end

    PersonaUpdater.stub(:new, updater) do
      assert_difference("Persona.count", 1) do
        post personas_path, params: { persona: { primary_profile: "1" } }
      end
    end

    persona = @user.personas.find_by(primary_profile: true)
    assert_redirected_to profile_path(@user)
    assert_equal "Night Digger", persona.title
    assert_equal "gpt-test", persona.llm_model
  end

  test "creates a custom persona with a prompt" do
    updater = ->(*_args, **_kwargs) do
      Struct.new(:call).new(
        Persona.new(
          user: @user,
          title: "Cosmic Drift",
          summary: "A floating cosmic jazz profile.",
          min_year: 1968,
          max_year: 1983,
          genres: ["Jazz", "Funk / Soul"],
          keywords: ["cosmic", "warm"],
          prompt: "Build me a cosmic jazz persona.",
          llm_model: "gpt-test"
        ).tap(&:save!)
      )
    end

    PersonaUpdater.stub(:new, updater) do
      assert_difference("Persona.count", 1) do
        post personas_path, params: { persona: { prompt: "Build me a cosmic jazz persona." } }
      end
    end

    persona = @user.personas.order(:created_at).last
    assert_equal "Build me a cosmic jazz persona.", persona.prompt
    assert_not persona.primary_profile?
  end

  test "destroys a persona owned by the current user" do
    persona = @user.personas.create!(
      title: "Temporary",
      summary: "A short-lived persona.",
      min_year: 1980,
      max_year: 1990,
      genres: ["Rock"],
      keywords: ["direct"]
    )

    assert_difference("Persona.count", -1) do
      delete persona_path(persona)
    end

    assert_redirected_to profile_path(@user)
  end
end
