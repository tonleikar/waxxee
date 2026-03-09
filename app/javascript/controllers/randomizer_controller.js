import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    loading: { type: Number, default: 1200 },
    success: { type: Number, default: 900 },
    dissipate: { type: Number, default: 700 }
  }

  start(event) {
    event.preventDefault()
    if (this.running) return
    this.running = true

    this.element.classList.add("is-loading")
    this.element.setAttribute("aria-disabled", "true")

    setTimeout(() => {
      this.element.classList.remove("is-loading")
      this.element.classList.add("is-success")

      setTimeout(() => {
        this.element.classList.remove("is-success")
        this.element.classList.add("is-dissipating")

        setTimeout(() => {
          window.location.href = this.element.href
        }, this.dissipateValue)
      }, this.successValue)
    }, this.loadingValue)
  }
}
