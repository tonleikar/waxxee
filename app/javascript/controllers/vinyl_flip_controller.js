import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  flipToBack(event) {
    event?.preventDefault()
    event?.stopPropagation()
    if (this.element.classList.contains("is-flipped")) return
    this.element.classList.add("is-flipped")
  }

  flipToFront(event) {
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.remove("is-flipped")
  }

  close(event) {
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.remove("is-flipped")
  }
}
