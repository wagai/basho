import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "frame", "prefecture", "city", "town"]
  static values = { url: String, delay: { type: Number, default: 300 } }

  connect() {
    this.frameTarget.addEventListener("turbo:frame-load", this.#fillFields)
  }

  disconnect() {
    this.frameTarget.removeEventListener("turbo:frame-load", this.#fillFields)
    clearTimeout(this.timeout)
  }

  lookup() {
    clearTimeout(this.timeout)
    const code = this.inputTarget.value.replace(/-/g, "")
    if (code.length < 7) return

    this.timeout = setTimeout(() => {
      this.frameTarget.src = `${this.urlValue}?code=${code}`
    }, this.delayValue)
  }

  #fillFields = () => {
    const data = this.frameTarget.querySelector("[data-address]")
    if (!data) return

    if (this.hasPrefectureTarget) this.prefectureTarget.value = data.dataset.prefecture || ""
    if (this.hasCityTarget) this.cityTarget.value = data.dataset.city || ""
    if (this.hasTownTarget) this.townTarget.value = data.dataset.town || ""
  }
}
