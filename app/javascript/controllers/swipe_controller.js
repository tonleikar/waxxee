import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, key: String, secret: String, persona: String }
  static targets = ["vinylWrapper", "template"]

  async connect() {
    // this.lockPageScroll()

    this.index = 0
    this.startX = 0
    this.currentX = 0
    this.dragging = false
    this.threshold = window.innerWidth * 0.3
    this.swiping = false

    this.audioPreview = null
    this.playPauseButton = null

    this.allPages = null
    this.totalPages = 1
    this.currentPage = 1

    this.currentVinyls = []
    this.activeVinyl = null
    this.discogsAPI = `${this.personaValue}&per_page=10&page=${this.currentPage}&key=${this.keyValue}&secret=${this.secretValue}`

    await this.getRecords()
    await this.renderCard()
  }

  // lockPageScroll() {
  //   this.scrollY = window.scrollY || window.pageYOffset || 0
  //   this.previousHtmlOverflow = document.documentElement.style.overflow
  //   this.previousBodyOverflow = document.body.style.overflow
  //   this.previousBodyPosition = document.body.style.position
  //   this.previousBodyTop = document.body.style.top
  //   this.previousBodyWidth = document.body.style.width

  //   document.documentElement.style.overflow = "hidden"
  //   document.body.style.overflow = "hidden"
  //   document.body.style.position = "fixed"
  //   document.body.style.top = `-${this.scrollY}px`
  //   document.body.style.width = "100%"
  // }

  // unlockPageScroll() {
  //   document.documentElement.style.overflow = this.previousHtmlOverflow || ""
  //   document.body.style.overflow = this.previousBodyOverflow || ""
  //   document.body.style.position = this.previousBodyPosition || ""
  //   document.body.style.top = this.previousBodyTop || ""
  //   document.body.style.width = this.previousBodyWidth || ""

  //   window.scrollTo(0, this.scrollY || 0)
  // }

  async getRecords() {
    let data = null
    console.log("Fetching records from:", this.discogsAPI)
    if (!this.allPages) {
      const response = await fetch(this.discogsAPI)
      data = await response.json()
      this.totalPages = data.pagination?.pages || 1
      this.allPages = Array.from({ length: this.totalPages }, (_, i) => i + 1).filter((page) => page !== this.currentPage)
    } else {
      if (this.allPages.length === 0) {
        this.allPages = Array.from({ length: this.totalPages }, (_, i) => i + 1)
      }

      const randomIndex = Math.floor(Math.random() * this.allPages.length)
      this.currentPage = this.allPages.splice(randomIndex, 1)[0]
      const response = await fetch(`${this.personaValue}&per_page=5&page=${this.currentPage}&key=${this.keyValue}&secret=${this.secretValue}`)
      data = await response.json()
    }
    this.currentVinyls = data.results || []
  }

  async renderCard() {
    if (this.audioPreview) this.audioPreview.pause()

    if (this.currentVinyls.length === 0) {
      this.activeVinyl = null
      await this.getRecords()
      if (this.currentVinyls.length === 0) return
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
    await this.playMusic(vinyl.title, card)
    this.audioPreview?.play()
    if (this.audioPreview && this.playPauseButton) {
      this.playPauseButton.innerHTML = "⏸"
    }

  }

  attachSwipe(card) {
    const start = (e) => {
      e.preventDefault()
      if (e.target.closest("button, a, input, select, textarea, [role='button']")) return

      this.dragging = true
      this.startX = e.touches ? e.touches[0].clientX : e.clientX
      this.currentX = this.startX
    }

    const move = (e) => {
      e.preventDefault()
      if (!this.dragging) return
      card.classList.remove("vinyl-card-animation")
      this.currentX = e.touches ? e.touches[0].clientX : e.clientX
      const diff = this.currentX - this.startX

      card.style.transform = `translateX(${diff}px) rotate(${diff * 0.01}deg)`
    }

    const end = () => {
      if (!this.dragging) return
      this.dragging = false;
      card.classList.add("vinyl-card-animation")

      const diff = this.currentX - this.startX

      let direction = null

      if (Math.abs(diff) > this.threshold) {
        console.log("Swiped", diff > 0 ? "right" : "left", "with diff:", diff)
        direction = diff > 0 ? "right" : "left"

        const bg = this.element.closest(".circles-bg")
        if (bg) this.spinBackground(bg)

        card.style.transform = `translateX(${diff > 0 ? 1000 : -1000}px) rotate(${diff * 0.1}deg)`

        if (direction === "right") {
          if (this.audioPreview) this.audioPreview.pause()
          this.saveVinyl(this.activeVinyl)
        }

        setTimeout(() => {
          this.index++
          this.renderCard()
        }, 150)

      } else if  (direction === "left") {
          if (this.audioPreview) {
          this.audioPreview.pause()
          this.audioPreview = null
        }
        card.style.transform = `translateX(0px) rotate(0deg)`
      } else {
        card.style.transform =`translateX(0px) rotate(0deg)`;
      }
    }

    card.addEventListener("pointerdown", start)
    card.addEventListener("pointermove", move)
    card.addEventListener("pointerup", end)

    // card.addEventListener("touchstart", start)
    // card.addEventListener("touchmove", move)
    // card.addEventListener("touchend", end)
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
    const youtubeLink = card.querySelector('[data-swipe-field="youtube-link"] a, a[data-swipe-field="youtube-link"], a[href*="youtube.com/results?search_query="]')
    const discogsLink = card.querySelector('[data-swipe-field="discogs-link"] a, a[data-swipe-field="discogs-link"], a[href*="discogs.com/release/"]')

    card.dataset.discogsId = vinyl.id || ""

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
    if (youtubeLink) {
      const query = [vinyl.title, this.artistName(vinyl)].filter(Boolean).join(" ")
      youtubeLink.href = `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}`
    }
    if (discogsLink && vinyl.id) {
      discogsLink.href = `https://www.discogs.com/release/${encodeURIComponent(vinyl.id)}`
    }
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

  async playMusic(query, card) {
    const searchUrl = `https://api.deezer.com/search?q=${encodeURIComponent(query)}`
    const data = await fetch(`/swiper/music_preview?query=${encodeURIComponent(searchUrl)}`).then(res => res.json())
    this.playPauseButton = card?.querySelector(".randomizer-sleeve__play") || null
    if (data.previewUrl) {
      this.audioPreview = new Audio(data.previewUrl)
      this.audioPreview.loop = true
      this.playPauseButton?.classList.remove("d-none")
    }
  }

  playPreview(event) {
    if (!this.audioPreview) return

    const playButton = event.currentTarget
    if (this.audioPreview.paused){
      this.audioPreview.play()
      playButton.innerHTML = "⏸"
    }else{
      this.audioPreview.pause()
      playButton.innerHTML = "▶"
    }
}

  disconnect() {
    if (this.audioPreview) {
      this.audioPreview.pause()
      this.audioPreview = null
    }

    // this.unlockPageScroll()
  }
}
