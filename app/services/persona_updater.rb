class PersonaUpdater
  DEFAULT_PROMPT = Openai::PersonaGenerator::DEFAULT_PROMPT

  def initialize(user:, prompt: nil, primary_profile: false)
    @user = user
    @prompt = prompt.presence
    @primary_profile = primary_profile
  end

  attr_reader :user, :prompt, :primary_profile

  def call
    generator = Openai::PersonaGenerator.new(user: user, prompt: prompt)
    persona_attributes = generator.call

    persona = if primary_profile
      user.personas.where(primary_profile: true).first_or_initialize
    else
      user.personas.new
    end

    persona.assign_attributes(
      persona_attributes.merge(
        prompt: prompt,
        primary_profile: primary_profile,
        llm_model: generator.model_name
      )
    )
    persona.primary_profile = primary_profile
    persona.save!
    persona
  end
end
