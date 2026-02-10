import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "frame", "fields", "prefecture", "city", "town"]
  static values = { url: String }

  lookup() {
    const code = this.inputTarget.value.replace(/-/g, "")

    if (code.length < 7) {
      this.#setAddress()
      return
    }

    this.frameTarget.src = `${this.urlValue}?code=${encodeURIComponent(code)}`
  }

  fill() {
    const el = this.frameTarget.querySelector("[data-address]")
    if (el) this.#setAddress(el.dataset)
  }

  #setAddress(data) {
    if (this.hasPrefectureTarget) this.prefectureTarget.value = data?.prefecture || ""
    if (this.hasCityTarget) this.cityTarget.value = data?.city || ""
    if (this.hasTownTarget) this.townTarget.value = data?.town || ""
    if (this.hasFieldsTarget) this.fieldsTarget.hidden = !data
  }
}
