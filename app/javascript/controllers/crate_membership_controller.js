import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    removeCard: Boolean
  }

  async remove(event) {
    event.preventDefault()

    const response = await fetch(this.element.action, {
      method: "DELETE",
      credentials: "same-origin",
      headers: {
        "Accept": "text/vnd.turbo-stream.html, text/html",
        "X-CSRF-Token": this.csrfToken,
        "X-Requested-With": "XMLHttpRequest"
      }
    })

    if (!response.ok) return

    const contentType = response.headers.get("content-type") || ""
    const body = await response.text()

    if (contentType.includes("text/vnd.turbo-stream.html")) {
      Turbo.renderStreamMessage(body)
    }

    if (this.removeCardValue) {
      this.element.closest("[data-crate-card]")?.remove()
      return
    }

    const frame = this.element.closest("turbo-frame")
    if (!frame || contentType.includes("text/vnd.turbo-stream.html")) return

    frame.outerHTML = body
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
