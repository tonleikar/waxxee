Rails.application.configure do
  config.x.discogs.base_url = ENV.fetch("DISCOGS_BASE_URL", "https://api.discogs.com")
  config.x.discogs.token = ENV["DISCOGS_USER_TOKEN"].presence || ENV["DISCOGS_TOKEN"]
  config.x.discogs.user_agent = ENV.fetch("DISCOGS_USER_AGENT", "Waxxee/1.0")
end
