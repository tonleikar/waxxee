import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "preview", "search"]

  connect() {
    if (!this.hasInputTarget) return
    this.syncSelectedState()
  }

  filter() {
    if (!this.hasSearchTarget) return

    const query = this.searchTarget.value.toLowerCase()
    this.element.querySelectorAll("[data-vinyl-picker-search]").forEach((result) => {
      result.classList.toggle("d-none", !result.dataset.vinylPickerSearch.includes(query))
    })
  }

  async select(event) {
    event.preventDefault()
    if (!this.hasInputTarget || !this.hasPreviewTarget || !this.hasFormTarget) return

    const button = event.currentTarget
    const {
      vinylPickerIdParam: id,
      vinylPickerTitleParam: title,
      vinylPickerArtistParam: artist,
      vinylPickerYearParam: year,
      vinylPickerGenreParam: genre,
      vinylPickerImageParam: image
    } = button.dataset

    this.inputTarget.value = id
    this.syncSelectedState()
    this.previewTarget.innerHTML = `
      <div class="profile-picked-vinyl">
        <img src="${image}" alt="${title}" class="profile-picked-vinyl-image">
        <div>
          <h2 class="h4 mb-1">${title}</h2>
          <p class="mb-1"><strong>Artist:</strong> ${artist || ""}</p>
          <p class="mb-1"><strong>Year:</strong> ${year || ""}</p>
          <p class="mb-0"><strong>Genre:</strong> ${genre || ""}</p>
        </div>
      </div>
    `

    try {
      const response = await fetch(this.formTarget.action, {
        method: "PATCH",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: new FormData(this.formTarget)
      })

      if (!response.ok) throw new Error(`Favorite save failed with status ${response.status}`)

      this.closePicker()
    } catch (error) {
      console.error(error)
    }
  }

  syncSelectedState() {
    const selectedId = this.inputTarget.value

    this.element.querySelectorAll("[data-vinyl-picker-option-id]").forEach((result) => {
      const isSelected = result.dataset.vinylPickerOptionId === selectedId
      result.classList.toggle("is-selected", isSelected)
      result.setAttribute("aria-pressed", isSelected ? "true" : "false")

      const badge = result.querySelector("[data-vinyl-picker-selected-badge]")
      if (badge) badge.classList.toggle("d-none", !isSelected)
    })
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }

  closePicker() {
    const picker = document.getElementById("favoriteVinylPicker")
    if (!picker || !window.bootstrap?.Offcanvas) return

    window.bootstrap.Offcanvas.getOrCreateInstance(picker).hide()
  }
}
