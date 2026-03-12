import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "input", "fileInput", "genderInput", "genderButton", "saveButton", "current", "status"]
  static values = { currentSourceType: String }

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
    if (!this.inputTarget.value && (!this.hasFileInputTarget || this.fileInputTarget.files.length === 0)) return
    if (this.hasCurrentTarget) {
      const shouldContinue = window.confirm("This will change your current profile picture. Continue?")
      if (!shouldContinue) return
    }

    this.saveButtonTarget.disabled = true
    this.setStatus("Saving profile picture...")

    try {
      const form = event.currentTarget
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
      if (payload.avatar_source_type) this.currentSourceTypeValue = payload.avatar_source_type
      this.setStatus("Profile picture saved.")
    } catch (error) {
      console.error(error)
      this.setStatus(error.message)
      this.saveButtonTarget.disabled = false
    }
  }

  uploadPreview() {
    if (!this.hasFileInputTarget || this.fileInputTarget.files.length === 0) return

    const [file] = this.fileInputTarget.files
    this.inputTarget.value = ""
    this.previewTarget.src = URL.createObjectURL(file)
    this.saveButtonTarget.disabled = false
    this.setStatus("Selected image ready to save.")
  }

  selectGender(event) {
    event.preventDefault()
    if (!this.hasGenderInputTarget) return

    const selectedValue = event.currentTarget.dataset.genderValue || ""
    this.genderInputTarget.value = selectedValue

    if (this.hasGenderButtonTarget) {
      this.genderButtonTargets.forEach((button) => {
        button.classList.toggle("is-active", button === event.currentTarget)
      })
    }
  }

  async loadGeneratedImage() {
    if (this.hasSaveButtonTarget) this.saveButtonTarget.disabled = true
    this.previewTarget.classList.add("is-loading")
    this.setStatus("Generating portrait...")

    try {
      const gender = this.hasGenderInputTarget ? this.genderInputTarget.value : ""
      const payload = await this.fetchPortrait(gender)
      const generatedUrl = payload.results?.[0]?.picture?.large

      if (!generatedUrl) throw new Error("Avatar generation returned no image")

      this.inputTarget.value = generatedUrl
      if (this.hasFileInputTarget) this.fileInputTarget.value = ""
      this.previewTarget.src = generatedUrl
      this.previewTarget.classList.remove("is-loading")
      this.setStatus("Generated image ready to save.")
    } catch (error) {
      console.error(error)
      const gender = this.hasGenderInputTarget ? this.genderInputTarget.value : ""
      this.setStatus(
        gender ?
          `Could not generate a matching ${gender} portrait. Try regenerate again.` :
          "Could not generate a portrait. Try regenerate again."
      )
    } finally {
      this.previewTarget.classList.remove("is-loading")
      if (this.hasSaveButtonTarget) {
        this.saveButtonTarget.disabled = !this.inputTarget.value && (!this.hasFileInputTarget || this.fileInputTarget.files.length === 0)
      }
    }
  }

  async fetchPortrait(gender, attempts = 10) {
    const query = new URLSearchParams({
      seed: String(Date.now()),
      inc: "gender,picture",
      noinfo: "1"
    })
    if (gender) query.set("gender", gender)

    const response = await fetch(`https://randomuser.me/api/?${query.toString()}`, {
      headers: { "Accept": "application/json" }
    })
    if (!response.ok) throw new Error(`Avatar generation failed with status ${response.status}`)

    const payload = await response.json()
    const returnedGender = payload.results?.[0]?.gender

    if (gender && returnedGender && returnedGender !== gender) {
      if (attempts <= 1) {
        throw new Error(`Avatar generation returned ${returnedGender} instead of ${gender}`)
      }

      return this.fetchPortrait(gender, attempts - 1)
    }

    return payload
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
