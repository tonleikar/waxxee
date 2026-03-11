import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "backdrop", "sleeve", "artwork", "title", "artist", "meta", "saveButton"]

  static values = {
    url: String,
    saveUrl: String,
    loading: { type: Number, default: 1200 },
    success: { type: Number, default: 900 },
    dissipate: { type: Number, default: 700 }
  }

  connect() {
    this.running = false
    this.currentVinyl = null
  }

  async start(event) {
    event?.preventDefault()
    if (this.running) return

    this.running = true
    this.currentVinyl = null
    this.resetSleeve()
    this.setTriggerDisabled(true)
    this.triggerTarget.classList.add("is-loading")

    try {
      const vinylPromise = this.fetchVinyl()
      await this.wait(this.loadingValue)
      const vinyl = await vinylPromise

      this.triggerTarget.classList.remove("is-loading")
      this.triggerTarget.classList.add("is-success")
      await this.wait(this.successValue)

      this.triggerTarget.classList.remove("is-success")
      this.triggerTarget.classList.add("has-result")
      this.backdropTarget.classList.add("is-visible")
      this.sleeveTarget.classList.add("is-visible")
      this.renderVinyl(vinyl)
      this.sleeveTarget.classList.add("is-ready")
      await this.wait(this.dissipateValue)
    } catch (error) {
      console.error("Randomizer failed", error)
    } finally {
      this.triggerTarget.classList.remove("is-loading", "is-success", "is-dissipating")
      this.running = false
      this.setTriggerDisabled(false)
    }
  }

  async tryAgain(event) {
    event.preventDefault()
    if (this.running) return

    await this.hideSleeve()
    this.start()
  }

  async close(event) {
    event.preventDefault()
    if (this.running) return

    await this.hideSleeve()
  }

  async saveToCollection(event) {
    event.preventDefault()
    if (!this.currentVinyl || this.saveButtonTarget.disabled) return

    this.saveButtonTarget.disabled = true

    try {
      const response = await fetch(this.saveUrlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
          "X-CSRF-Token": this.csrfToken
        },
        body: new URLSearchParams({
          "user_vinyl[vinyl_id]": this.currentVinyl.id
        })
      })

      if (!response.ok) throw new Error(`Save failed with status ${response.status}`)

      this.saveButtonTarget.textContent = "Saved in collection"
      this.saveButtonTarget.classList.remove("btn-light")
      this.saveButtonTarget.classList.add("btn-secondary")
    } catch (error) {
      console.error("Saving vinyl failed", error)
      this.saveButtonTarget.disabled = false
      this.saveButtonTarget.textContent = "Save failed"
    }
  }

  async fetchVinyl() {
    const response = await fetch(this.urlValue, {
      headers: { "Accept": "application/json" }
    })

    if (!response.ok) {
      throw new Error(`Request failed with status ${response.status}`)
    }

    return response.json()
  }

  renderVinyl(vinyl) {
    this.currentVinyl = vinyl
    this.artworkTarget.src = vinyl.artwork_url || ""
    this.artworkTarget.alt = vinyl.title ? `${vinyl.title} cover` : "Vinyl artwork"
    this.titleTarget.textContent = vinyl.title || "Untitled"
    this.artistTarget.textContent = vinyl.artist || "Unknown artist"
    this.metaTarget.textContent = [vinyl.year, vinyl.genre].filter(Boolean).join(" • ")

    this.saveButtonTarget.disabled = Boolean(vinyl.saved)
    this.saveButtonTarget.textContent = vinyl.saved ? "Saved in collection" : "Save to collection"
    this.saveButtonTarget.classList.remove("btn-secondary")
    this.saveButtonTarget.classList.add(vinyl.saved ? "btn-secondary" : "btn-light")
    if (vinyl.saved) this.saveButtonTarget.classList.remove("btn-light")
  }

  resetSleeve() {
    this.sleeveTarget.classList.remove("is-visible", "is-ready")
    this.backdropTarget.classList.remove("is-visible")
    this.triggerTarget.classList.remove("has-result")
  }

  async hideSleeve() {
    if (!this.sleeveTarget.classList.contains("is-visible")) return

    this.sleeveTarget.classList.remove("is-ready")
    this.sleeveTarget.classList.remove("is-visible")
    this.backdropTarget.classList.remove("is-visible")
    this.triggerTarget.classList.remove("has-result")
    await this.wait(450)
  }

  setTriggerDisabled(disabled) {
    this.triggerTarget.toggleAttribute("disabled", disabled)
    this.triggerTarget.setAttribute("aria-disabled", disabled ? "true" : "false")
  }

  wait(duration) {
    return new Promise((resolve) => setTimeout(resolve, duration))
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
