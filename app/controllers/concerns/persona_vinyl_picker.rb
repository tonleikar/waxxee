module PersonaVinylPicker
  private

  def filtered_vinyl_scope(persona)
    scope = Vinyl.where(year: persona[:min_year]..persona[:max_year])

    return scope if persona[:genres] == [""]

    scope.where(
      persona[:genres].map { "genre ILIKE ?" }.join(" OR "),
      *persona[:genres].map { |genre| "%#{genre}%" }
    )
  end
end
