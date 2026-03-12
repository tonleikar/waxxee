module PersonaVinylPicker
  private

  def filtered_vinyl_scope(persona)
    config = persona.respond_to?(:picker_rule) ? persona.picker_rule : persona
    scope = Vinyl.where(year: config[:min_year]..config[:max_year])
    genres = Array(config[:genres]).reject(&:blank?)

    return scope if genres.empty?

    scope.where(
      genres.map { "genre ILIKE ?" }.join(" OR "),
      *genres.map { |genre| "%#{genre}%" }
    )
  end
end
