class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  PERSONA_RULES = {
    "grungie" => {
      title: "Grungie",
      min_year: 1988,
      max_year: 1999,
      genres: ["Grunge", "Alternative Rock", "Post-Grunge"]
    },
    "emo" => {
      title: "Emo",
      min_year: 1995,
      max_year: 2010,
      genres: ["Emo", "Pop Punk", "Post-Hardcore"]
    },
    "dreamy" => {
      title: "Dreamy",
      min_year: 1983,
      max_year: 2025,
      genres: ["Dream Pop", "Shoegaze", "Indie Pop"]
    },
    "throwback" => {
      title: "Throwback",
      min_year: 1965,
      max_year: 1989,
      genres: ["Soul", "Funk", "Disco", "Classic Rock"]
    },
    "midnight" => {
      title: "Midnight",
      min_year: 1990,
      max_year: 2025,
      genres: ["Trip Hop", "Ambient", "Downtempo", "Lo-Fi"]
    }
  }

  def home
    @persona_key = selected_persona_key
    @persona = PERSONA_RULES.fetch(@persona_key)
    @personas = PERSONA_RULES.map { |key, rule| { key: key, title: rule[:title] } }
    @vinyl = random_vinyl_for_persona(@persona)
  end

  private

  def random_vinyl_for_persona(persona)
    Vinyl.where(
      year: persona[:min_year]..persona[:max_year],
      genre: persona[:genres]
    ).sample
  end

  def selected_persona_key
    params[:persona].downcase
  end
end
