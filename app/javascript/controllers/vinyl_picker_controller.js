import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "preview", "search"]

  connect() {
    this.syncSelectedState()
  }

  filter() {
    const query = this.searchTarget.value.toLowerCase()
    this.element.querySelectorAll("[data-vinyl-picker-search]").forEach((result) => {
      result.classList.toggle("d-none", !result.dataset.vinylPickerSearch.includes(query))
    })
  }

  select(event) {
    const { id, title, artist, year, image } = event.params

    this.inputTarget.value = id
    this.syncSelectedState()
    this.previewTarget.innerHTML = `
      <img src="${image}" alt="${title}" class="profile-picked-vinyl-image">
      <div>
        <h2 class="h6 mb-1">${title}</h2>
        <p class="mb-0 small text-muted">${artist} • ${year}</p>
      </div>
    `
    this.formTarget.requestSubmit()
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
}
