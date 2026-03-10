import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { vinyls: Array, url: String }
  static targets = ["form", "vinylId", "vinylWrapper"]

  connect() {
    this.index = 0
    this.startX = 0
    this.currentX = 0
    this.dragging = false
    this.threshold = 120

    this.renderCard()
  }

  renderCard() {
    if (this.index >= this.vinylsValue.length) {
      this.vinylWrapperTarget.innerHTML = "<p>No more records</p>"
      return
    }

    const vinyl = this.vinylsValue[this.index]

    this.vinylWrapperTarget.innerHTML = `
      <div class="vinyl-card" data-id="${vinyl.id}">
        <img src="${vinyl.artwork_url}">
      </div>
    `

    const card = this.element.querySelector(".vinyl-card")

    setTimeout(() => {
      card.classList.add("active")
    }, 50)

    this.attachSwipe(card)
  }

  attachSwipe(card) {

    const start = (e) => {
      this.dragging = true
      this.startX = e.touches ? e.touches[0].clientX : e.clientX
    }

    const move = (e) => {
      if (!this.dragging) return

      this.currentX = e.touches ? e.touches[0].clientX : e.clientX
      const diff = this.currentX - this.startX

      card.style.transform = `translateX(${diff}px) rotate(${diff * -0.01}deg)`
    }

    const end = () => {
      if (!this.dragging) return

      const diff = this.currentX - this.startX

      if (Math.abs(diff) > this.threshold) {

        const direction = diff > 0 ? "right" : "left"

        card.style.transform =
          `translateX(${diff > 0 ? 600 : -600}px) rotate(${diff * 0.1}deg)`

        card.style.opacity = 0

        if (direction === "right") {
          const id = card.dataset.id
          console.log("Save vinyl:", id)
          console.log(this.urlValue)
          console.log(this.c)
          this.vinylIdTarget.value = id;

          fetch(this.urlValue, {
            method: "POST",
            headers: {"X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content, "Accept": "application/json" },
            body: new FormData(this.formTarget)
          })
            .then(response => response.json())
            .then((data) => {
              console.log(data)
            })

        }

        setTimeout(() => {
          this.index++
          this.renderCard()
        }, 150)

      } else {
        card.style.transform = ""
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
}
