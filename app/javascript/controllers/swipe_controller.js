import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, key: String, secret: String }
  static targets = ["vinylWrapper", "template"]

  async connect() {
    this.index = 0
    this.startX = 0
    this.currentX = 0
    this.dragging = false
    this.threshold = 100
    this.swiping = false

    this.currentVinyls = []
    this.currentPage = 1
    this.activeVinyl = null
    this.discogsAPI = `https://api.discogs.com/database/search?style=rock&country=brazil&decade=2000&type=release&per_page=100&page=1&key=${this.keyValue}&secret=${this.secretValue}`

    await this.getRecords()
    await this.renderCard()
  }

  async getRecords() {
    const response = await fetch(this.discogsAPI)
    const data = await response.json()

    this.currentVinyls = data.results || []
  }

  async renderCard() {
    if (this.currentVinyls.length === 0) {
      this.activeVinyl = null
      this.vinylWrapperTarget.innerHTML = "<p>No more records</p>"
      return
    }

    const randomIndex = Math.floor(Math.random() * this.currentVinyls.length)
    const vinyl = this.currentVinyls.splice(randomIndex, 1)[0]
    this.activeVinyl = vinyl

    const cardCopy = this.templateTarget.content.cloneNode(true).querySelector(".vinyl-card")
    cardCopy.dataset.discogsId = vinyl.id
    this.populateCard(cardCopy, vinyl)

    this.vinylWrapperTarget.innerHTML = ""
    this.vinylWrapperTarget.appendChild(cardCopy)

    const card = this.element.querySelector(".vinyl-card")
    if (!card) return

    setTimeout(() => {
      card.classList.add("active")
      const sleeve = card.querySelector(".swiper-sleeve")
      sleeve?.classList.add("is-visible")
      sleeve?.classList.add("is-ready")
    }, 100)

    this.attachSwipe(card)
  }

  attachSwipe(card) {
    const start = (e) => {
      if (e.target.closest("button")) return

      e.preventDefault()
      this.dragging = true
      this.startX = e.touches ? e.touches[0].clientX : e.clientX
      this.currentX = this.startX
    }

    const move = (e) => {
      e.preventDefault()
      if (!this.dragging) return

      this.currentX = e.touches ? e.touches[0].clientX : e.clientX
      const diff = this.currentX - this.startX

      card.style.transform = `translateX(${diff}px) rotate(${diff * -0.01}deg)`
    }

    const end = () => {
      if (!this.dragging) return

      const diff = this.currentX - this.startX

      if (Math.abs(diff) > 25) {
        if (Math.abs(diff) > this.threshold) {
          const direction = diff > 0 ? "right" : "left"

          const bg = this.element.closest(".circles-bg")
          if (bg) this.spinBackground(bg)

          card.style.transform = `translateX(${diff > 0 ? 600 : -600}px) rotate(${diff * 0.1}deg)`

          card.style.opacity = 0

          if (direction === "right") {
            this.saveVinyl(this.activeVinyl)
          }

          setTimeout(() => {
            this.index++
            this.renderCard()
          }, 150)

        } else {
          card.style.transform = ""
        }
      }

      this.dragging = false
    }

    card.addEventListener("mousedown", start)
    card.addEventListener("mousemove", move)
    card.addEventListener("mouseup", end)

    card.addEventListener("touchstart", start)
    card.addEventListener("touchmove", move)
    card.addEventListener("touchend", end)
  }

  flipToBack(event) {
    event.preventDefault()
    event.stopPropagation()

    const sleeve = event.currentTarget.closest(".swiper-sleeve")
    sleeve.classList.add("is-flipped")
  }

  flipToFront(event) {
    event.preventDefault()
    event.stopPropagation()

    const sleeve = event.currentTarget.closest(".swiper-sleeve")
    sleeve?.classList.remove("is-flipped")
  }

  async saveVinyl(vinyl) {
    if (!vinyl) return

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: JSON.stringify({
          release_id: vinyl.id,
          cover_image: vinyl.cover_image
        })
      })

      const data = await response.json().catch(() => ({}))

      if (!response.ok) {
        this.showToast(data.error || "Could not save this release.", "neutral")
        return
      }

      this.showToast(data.message, "success")
    } catch (_error) {
      this.showToast("Could not save this release.", "neutral")
    }
  }

  showToast(message, tone = "success") {
    let stack = document.querySelector(".toast-stack")
    if (!stack) {
      stack = document.createElement("div")
      stack.className = "toast-stack"
      stack.setAttribute("aria-live", "polite")
      stack.setAttribute("aria-atomic", "true")
      document.body.appendChild(stack)
    }

    const toast = document.createElement("div")
    toast.className = `app-toast app-toast--${tone}`
    toast.setAttribute("role", "status")
    toast.textContent = message
    stack.appendChild(toast)

    toast.addEventListener("animationend", () => toast.remove())
  }

  spinBackground(bg) {
    bg.querySelectorAll(".circles-bg__ring").forEach((ring, index) => {
      const current = Number(ring.dataset.rotation || 0)
      const next = current + (index % 2 === 0 ? 42 : -42)
      ring.dataset.rotation = String(next)
      ring.style.transform = `rotate(${next}deg)`
    })
  }

  populateCard(card, vinyl) {
    const artwork = card.querySelector('[data-swipe-field="artwork"]')
    const title = card.querySelector('[data-swipe-field="title"]')
    const artist = card.querySelector('[data-swipe-field="artist"]')
    const year = card.querySelector('[data-swipe-field="year"]')
    const yearRow = card.querySelector('[data-swipe-field-row="year"]')
    const genre = card.querySelector('[data-swipe-field="genre"]')

    if (artwork) {
      artwork.src = vinyl.cover_image || artwork.src
      artwork.alt = vinyl.title ? `${vinyl.title} cover` : "album cover"
    }

    if (title) title.textContent = vinyl.title || "Untitled"
    if (artist) artist.textContent = this.artistName(vinyl)
    if (year) {
      const displayYear = this.displayYear(vinyl.year)
      year.textContent = displayYear || ""
      yearRow?.toggleAttribute("hidden", !displayYear)
    }
    if (genre) genre.textContent = this.genreName(vinyl)
  }

  displayYear(year) {
    const numericYear = Number(year)
    return Number.isFinite(numericYear) && numericYear > 0 ? String(year) : null
  }

  artistName(vinyl) {
    if (vinyl.artist) return vinyl.artist
    if (vinyl.artists?.length) return vinyl.artists.join(", ")

    const [artist] = (vinyl.title || "").split(" - ")
    return artist || "Unknown artist"
  }

  genreName(vinyl) {
    if (Array.isArray(vinyl.genre) && vinyl.genre.length) return vinyl.genre.join(", ")
    if (Array.isArray(vinyl.style) && vinyl.style.length) return vinyl.style.join(", ")
    if (typeof vinyl.genre === "string" && vinyl.genre.length > 0) return vinyl.genre

    return "Unlisted"
  }
}
