import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "trigger",
    "backdrop",
    "sleeve",
    "artwork",
    "backTitle",
    "detailArtist",
    "detailYear",
    "detailGenre",
    "saveButton"
  ]

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
      await this.preloadArtwork(vinyl.artwork_url)
      this.renderVinyl(vinyl)

      this.triggerTarget.classList.remove("is-loading")
      this.triggerTarget.classList.add("is-success")
      await this.wait(this.successValue)

      this.triggerTarget.classList.remove("is-success")
      this.triggerTarget.classList.add("has-result")
      this.backdropTarget.classList.add("is-visible")
      this.sleeveTarget.classList.add("is-visible")
      await this.wait(80)
      this.sleeveTarget.classList.add("is-engulfing")
      await this.wait(650)
      this.triggerTarget.classList.add("is-engulfed")
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

  flipToBack(event) {
    event.preventDefault()
    if (!this.sleeveTarget.classList.contains("is-ready")) return

    this.sleeveTarget.classList.add("is-flipped")
  }

  flipToFront(event) {
    event.preventDefault()
    this.sleeveTarget.classList.remove("is-flipped")
  }

  async saveToCollection(event) {
    event.preventDefault()
    if (!this.currentVinyl || this.saveButtonTarget.disabled) return

    this.saveButtonTarget.disabled = true

    try {
      const response = await fetch(this.saveUrlValue, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          user_vinyl: {
            vinyl_id: this.currentVinyl.id
          }
        })
      })

      const payload = await response.json().catch(() => ({}))
      if (!response.ok) throw new Error(payload.error || `Save failed with status ${response.status}`)

      this.saveButtonTarget.textContent = "Saved"
      this.saveButtonTarget.classList.add("is-saved")
    } catch (error) {
      console.error("Saving vinyl failed", error)
      this.saveButtonTarget.disabled = false
      this.saveButtonTarget.textContent = "Error"
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
    this.backTitleTarget.textContent = vinyl.title || "Untitled"
    this.detailArtistTarget.textContent = vinyl.artist || "Unknown artist"
    this.detailYearTarget.textContent = vinyl.year || "Unknown"
    this.detailGenreTarget.textContent = vinyl.genre || "Unlisted"

    this.saveButtonTarget.disabled = Boolean(vinyl.saved)
    this.saveButtonTarget.textContent = vinyl.saved ? "Saved" : "Save"
    this.saveButtonTarget.classList.toggle("is-saved", Boolean(vinyl.saved))
  }

  resetSleeve() {
    this.sleeveTarget.classList.remove("is-visible", "is-ready", "is-engulfing", "is-flipped")
    this.backdropTarget.classList.remove("is-visible")
    this.triggerTarget.classList.remove("has-result", "is-engulfed")
  }

  async hideSleeve() {
    if (!this.sleeveTarget.classList.contains("is-visible")) return

    this.sleeveTarget.classList.remove("is-ready")
    this.sleeveTarget.classList.remove("is-engulfing", "is-flipped", "is-visible")
    this.backdropTarget.classList.remove("is-visible")
    this.triggerTarget.classList.remove("has-result", "is-engulfed")
    await this.wait(450)
  }

  preloadArtwork(url) {
    if (!url) return Promise.resolve()

    return new Promise((resolve) => {
      const image = new Image()
      image.onload = () => resolve()
      image.onerror = () => resolve()
      image.src = url

      if (image.complete) resolve()
    })
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
