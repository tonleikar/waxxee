import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "search"]

  filter() {
    const query = this.searchTarget.value.toLowerCase()
    this.element.querySelectorAll("[data-vinyl-picker-search]").forEach((result) => {
      result.classList.toggle("d-none", !result.dataset.vinylPickerSearch.includes(query))
    })
  }

  select(event) {
    const { id, title, artist, year, image } = event.params

    this.inputTarget.value = id
    this.previewTarget.innerHTML = `
      <img src="${image}" alt="${title}" class="profile-picked-vinyl-image">
      <div>
        <h2 class="h6 mb-1">${title}</h2>
        <p class="mb-0 small text-muted">${artist} • ${year}</p>
      </div>
    `
  }
}
