import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { vinyls: Array, url: String, cardUrl: String, key: String, secret: String }
  static targets = ["form", "vinylId", "vinylWrapper", "backButton"]

  connect() {
    this.index = 0
    this.startX = 0
    this.currentX = 0
    this.dragging = false
    this.threshold = 100
    this.swiping = false

    this.currentVinyls = []
    this.currentPage = 1
    this.discogsAPI = `https://api.discogs.com/database/search?style=psychedelic&country=turkey&decade=1960&type=release&per_page=100&page=1&key=${this.keyValue}&secret=${this.secretValue}`

    this.getRecords()
    this.renderCard()


  }

  getRecords() {
    console.log(`${this.discogsAPI}$&key=${this.keyValue}&secret=${this.secretValue}`)
      fetch(this.discogsAPI, {
      })
      .then((res) => res.json())
      .then((data) => {
        console.log(data);
        this.currentVinyls = data.results || [];
        console.log("Fetched records:", this.currentVinyls);
      });
    }

      async renderCard() {
        if (this.currentVinyls.length === 0) {
          this.vinylWrapperTarget.innerHTML = "<p>No more records</p>"
          this.getRecords()
          return
        } else {
          const vinyl = this.currentVinyls[randonmInt(0, this.currentVinyls.length - 1)]
          const data = JSON.stringify({"vinyl": vinyl})

          fetch("/vinyls", {
          method: "POST",
          headers: {
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
            "Content-Type": "application/json"
          },
          body: data
        })
      }

      // rework partial to render the json
      // delete instance in array
      // have a create method that makes vinyl model and then associated user_vinyl


    // ============== OLD CODE TO GET FROM LOCAL DB ================
    // const id = this.vinylsValue[this.index]
    // const url = this.cardUrlValue.replace("__id__", id)
    // const response = await fetch(url, { headers: { "Accept": "text/html" } })
    // this.vinylWrapperTarget.innerHTML = await response.text()

    const card = this.element.querySelector(".vinyl-card")

    setTimeout(() => {
      card.classList.add("active")
    }, 100)

    this.attachSwipe(card)
  }

  attachSwipe(card) {

    const start = (e) => {
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
          if (bg) {
            bg.classList.remove("swipe-bg-pulse")
            void bg.offsetWidth
            bg.classList.add("swipe-bg-pulse")
            bg.addEventListener("animationend", () => bg.classList.remove("swipe-bg-pulse"), { once: true })
          }

          card.style.transform =
            `translateX(${diff > 0 ? 600 : -600}px) rotate(${diff * 0.1}deg)`

          card.style.opacity = 0

          if (direction === "right") {
            const id = card.dataset.id
            console.log("Save vinyl:", id)
            this.vinylIdTarget.value = id;

            fetch(this.urlValue, {
              method: "POST",
              headers: {"X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content, "Accept": "application/json" },
              body: new FormData(this.formTarget)
            })
              .then(response => response.json())
              .then((data) => {
                console.log(data.message)
                this.showToast(data.message)
              })

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

    const flipCard = (e) => {
      e.stopPropagation()
      e.preventDefault()
      const inner = card.querySelector(".vinyl-card-inner")
      inner.classList.toggle("flipped")
    }

    card.addEventListener("mousedown", start)
    card.addEventListener("mousemove", move)
    card.addEventListener("mouseup", end)

    card.addEventListener("touchstart", start)
    card.addEventListener("touchmove", move)
    card.addEventListener("touchend", end)

    this.backButtonTargets.forEach((btn) => {
      btn.addEventListener("click", flipCard)
      btn.addEventListener("touchend", flipCard)
      btn.addEventListener("mousedown", (e) => e.stopPropagation())
      btn.addEventListener("touchstart", (e) => e.stopPropagation())
    })
  }

  showToast(message) {
    let stack = document.querySelector(".toast-stack")
    if (!stack) {
      stack = document.createElement("div")
      stack.className = "toast-stack"
      stack.setAttribute("aria-live", "polite")
      stack.setAttribute("aria-atomic", "true")
      document.body.appendChild(stack)
    }

    const toast = document.createElement("div")
    toast.className = "app-toast app-toast--success"
    toast.setAttribute("role", "status")
    toast.textContent = message
    stack.appendChild(toast)

    toast.addEventListener("animationend", () => toast.remove())
  }
}
