import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prefecture", "city"]
  static values = {
    prefecturesUrl: String,
    citiesUrlTemplate: String
  }

  connect() {
    this.abortController = new AbortController()

    if (this.prefectureTarget.options.length <= 1) {
      this.#loadPrefectures()
    }
  }

  disconnect() {
    this.abortController.abort()
  }

  prefectureChanged() {
    const code = this.prefectureTarget.value
    this.#clearOptions(this.cityTarget)

    if (!code) return

    this.#loadCities(code)
  }

  async #loadPrefectures() {
    try {
      const response = await fetch(this.prefecturesUrlValue, {
        signal: this.abortController.signal
      })
      if (!response.ok) return

      const prefectures = await response.json()
      prefectures.forEach(({ code, name }) => {
        this.prefectureTarget.appendChild(new Option(name, code))
      })
    } catch (error) {
      if (error.name !== "AbortError") {
        this.dispatch("error", { detail: { message: "Failed to load prefectures", error } })
      }
    }
  }

  async #loadCities(code) {
    if (!/^\d{1,2}$/.test(code)) return

    try {
      const url = this.citiesUrlTemplateValue.replace(":code", encodeURIComponent(code))
      const response = await fetch(url, {
        signal: this.abortController.signal
      })
      if (!response.ok) return

      const cities = await response.json()
      cities.forEach(({ code, name }) => {
        this.cityTarget.appendChild(new Option(name, code))
      })
    } catch (error) {
      if (error.name !== "AbortError") {
        this.dispatch("error", { detail: { message: "Failed to load cities", error } })
      }
    }
  }

  #clearOptions(select) {
    const hasPlaceholder = select.options[0] && !select.options[0].value
    const start = hasPlaceholder ? 1 : 0
    while (select.options.length > start) {
      select.remove(start)
    }
  }
}
