class Persona < ApplicationRecord
  belongs_to :user, optional: true

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
      genres: ["Electronic", "Hip Hop", "Funk / Soul"],
      url: "https://api.discogs.com/database/search?&genre=Electronic&genre=Hip+Hop&genre=Funk+%2F+Soul&decade=1990&type=release"
    }
  }.freeze

  scope :generated_for_profile, -> { where.not(user_id: nil).order(primary_profile: :desc, created_at: :desc) }

  validates :title, presence: true

  def self.rule_for(key)
    RULES[key.to_s.downcase]
  end

  def picker_rule
    {
      title: title,
      min_year: min_year || 1900,
      max_year: max_year || Time.current.year,
      genres: Array(genres).reject(&:blank?).presence || [""]
    }
  end

  def custom_prompt?
    prompt.present? && !primary_profile?
  end

  def generated?
    user_id.present?
  end
end
