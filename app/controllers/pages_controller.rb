class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]
  PERSONA_RULES = {
    "randomizer" => {
      title: "Randomizer",
      min_year: 1900,
      max_year: 2100,
      genres: [""]
    },
    "grungie" => {
      title: "Grungie",
      min_year: 1988,
      max_year: 1999,
      genres: ["Rock"]
    },
    "emo" => {
      title: "Emo",
      min_year: 1995,
      max_year: 2010,
      genres: ["Rock", "Pop"]
    },
    "dreamy" => {
      title: "Dreamy",
      min_year: 1983,
      max_year: 2025,
      genres: ["Electronic", "Pop", "Rock"]
    },
    "throwback" => {
      title: "Throwback",
      min_year: 1965,
      max_year: 1989,
      genres: ["Funk / Soul", "Jazz", "Blues", "Rock"]
    },
    "midnight" => {
      title: "Midnight",
      min_year: 1990,
      max_year: 2025,
      genres: ["Electronic", "Hip Hop", "Funk / Soul"]
    }
  }
  def home
    @personas = PERSONA_RULES.map { |key, rule| { key: key, title: rule[:title] } }
    @persona_key = selected_persona_key
    @persona = PERSONA_RULES.fetch(@persona_key)
    @vinyl = random_vinyl_for_persona(@persona)
  end

  private

  def random_vinyl_for_persona(persona)
    Vinyl
      .where(year: persona[:min_year]..persona[:max_year])
      .where(
        persona[:genres].map { "genre ILIKE ?" }.join(" OR "),
        *persona[:genres].map { |genre| "%#{genre}%" }
      ).sample
  end

  def selected_persona_key
    (params[:persona] || "randomizer").downcase
  end
end
