import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button", "input"]
  static classes = ["open"]

  connect() {
    this.isOpen = this.buttonTargets.some((button) => button.getAttribute("aria-expanded") === "true")
    this.closeDelay = 180
    this.panelTarget.hidden = !this.isOpen
    this.panelTarget.style.height = this.isOpen ? "auto" : "0px"
    this.panelTarget.style.opacity = this.isOpen ? "1" : "0"
    this.panelTarget.style.transform = this.isOpen ? "translateY(0)" : "translateY(-8px)"
    this.syncButtons()
  }

  toggle() {
    this.isOpen = !this.isOpen
    if (this.isOpen) {
      this.open()
    } else {
      this.close()
    }

    if (this.isOpen && this.hasInputTarget) {
      window.setTimeout(() => this.inputTarget.focus(), 520)
    }
  }

  open() {
    const panel = this.panelTarget
    panel.hidden = false
    panel.style.height = "0px"
    panel.style.opacity = "0"
    panel.offsetHeight
    panel.style.height = `${panel.scrollHeight}px`
    panel.style.opacity = "1"
    panel.style.transform = "translateY(0)"
    this.syncButtons()

    this.finishTransition = () => {
      if (!this.isOpen) return
      panel.style.height = "auto"
      panel.removeEventListener("transitionend", this.finishTransition)
    }

    panel.addEventListener("transitionend", this.finishTransition)
  }

  close() {
    const panel = this.panelTarget
    panel.style.height = `${panel.scrollHeight}px`
    panel.style.opacity = "1"
    panel.offsetHeight
    this.syncButtons()

    window.clearTimeout(this.closeTimer)
    this.closeTimer = window.setTimeout(() => {
      panel.style.height = "0px"
      panel.style.opacity = "0"
      panel.style.transform = "translateY(-8px)"
    }, this.closeDelay)

    this.finishTransition = () => {
      if (this.isOpen) return
      panel.hidden = true
      panel.removeEventListener("transitionend", this.finishTransition)
    }

    panel.addEventListener("transitionend", this.finishTransition)
  }

  syncButtons() {
    this.buttonTargets.forEach((button) => {
      button.setAttribute("aria-expanded", String(this.isOpen))
      button.classList.toggle(this.openClass, this.isOpen)
    })
  }
}
