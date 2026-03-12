import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "input", "saveButton", "current", "status"]
  static values = { previewUrl: String }

  connect() {
    if (!this.hasInputTarget || !this.hasPreviewTarget || !this.hasSaveButtonTarget) return
    this.saveButtonTarget.disabled = !this.inputTarget.value
  }

  async regenerate(event) {
    event.preventDefault()
    await this.loadGeneratedImage()
  }

  async save(event) {
    event.preventDefault()
    if (!this.inputTarget.value) return

    this.saveButtonTarget.disabled = true
    this.setStatus("Saving profile picture...")

    try {
      const form = event.currentTarget.form
      const response = await fetch(form.action, {
        method: "PATCH",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: new FormData(form)
      })

      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || `Save failed with status ${response.status}`)

      if (this.hasCurrentTarget) this.currentTarget.src = payload.avatar_url
      this.setStatus("Profile picture saved.")
    } catch (error) {
      console.error(error)
      this.setStatus(error.message)
      this.saveButtonTarget.disabled = false
    }
  }

  async loadGeneratedImage() {
    if (this.hasSaveButtonTarget) this.saveButtonTarget.disabled = true
    this.previewTarget.classList.add("is-loading")

    try {
      const separator = this.previewUrlValue.includes("?") ? "&" : "?"
      const response = await fetch(`${this.previewUrlValue}${separator}cb=${Date.now()}`, {
        headers: { "Accept": "application/json" },
        cache: "no-store"
      })
      if (!response.ok) throw new Error(`Avatar generation failed with status ${response.status}`)

      const payload = await response.json()
      const dataUrl = payload.image_data

      this.inputTarget.value = dataUrl
      this.previewTarget.src = dataUrl
      this.previewTarget.classList.remove("is-loading")
    } catch (error) {
      console.error(error)
    } finally {
      if (this.hasSaveButtonTarget) this.saveButtonTarget.disabled = !this.inputTarget.value
    }
  }

  setStatus(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("d-none", !message)
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }

}
