import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async remove(event) {
    event.preventDefault()

    const response = await fetch(this.element.action, {
      method: "DELETE",
      credentials: "same-origin",
      headers: {
        "Accept": "text/html",
        "X-CSRF-Token": this.csrfToken,
        "X-Requested-With": "XMLHttpRequest"
      }
    })

    if (!response.ok) return

    const html = await response.text()
    const frame = this.element.closest("turbo-frame")
    if (!frame) return

    frame.outerHTML = html
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
