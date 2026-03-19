import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["favoriteCard", "sideStack", "collectionCarousel"]

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
    this.collectionCarousel?.dispose()
  }

  updateLayout() {
    this.updateCollectionCarousel()

    if (!this.hasFavoriteCardTarget || !this.hasSideStackTarget) return

    if (window.innerWidth < 992) {
      this.sideStackTarget.style.removeProperty("max-height")
      return
    }

    const { height } = this.favoriteCardTarget.getBoundingClientRect()
    this.sideStackTarget.style.maxHeight = `${Math.round(height)}px`
  }

  updateCollectionCarousel() {
    if (!this.hasCollectionCarouselTarget || !window.bootstrap?.Carousel) return

    if (window.innerWidth >= 992) {
      this.collectionCarousel?.pause()
      return
    }

    this.collectionCarousel =
      this.collectionCarousel ||
      window.bootstrap.Carousel.getOrCreateInstance(this.collectionCarouselTarget, {
        interval: 3000,
        pause: false,
        ride: "carousel",
        touch: true
      })

    this.collectionCarousel.cycle()
  }
}
