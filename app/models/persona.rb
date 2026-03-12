class Persona < ApplicationRecord
  RULES = {
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
  }.freeze

  def self.rule_for(key)
    RULES[key.to_s.downcase]
  end
end
