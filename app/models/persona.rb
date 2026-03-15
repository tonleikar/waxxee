class Persona < ApplicationRecord
  belongs_to :user, optional: true

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
