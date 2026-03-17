import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["favoriteCard", "sideStack"]

  connect() {
    this.boundUpdate = this.updateLayout.bind(this)
    this.resizeObserver = new ResizeObserver(this.boundUpdate)

    if (this.hasFavoriteCardTarget) {
      this.resizeObserver.observe(this.favoriteCardTarget)
    }

    window.addEventListener("resize", this.boundUpdate)
    this.updateLayout()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    window.removeEventListener("resize", this.boundUpdate)
  }

  updateLayout() {
    if (!this.hasFavoriteCardTarget || !this.hasSideStackTarget) return

    if (window.innerWidth < 992) {
      this.sideStackTarget.style.removeProperty("max-height")
      return
    }

    const { height } = this.favoriteCardTarget.getBoundingClientRect()
    this.sideStackTarget.style.maxHeight = `${Math.round(height)}px`
  }
}
