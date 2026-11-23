import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "button"]

  disconnect() {
    clearTimeout(this.timeout)
  }

  async copy() {
    await navigator.clipboard.writeText(this.textTarget.value)
    this.buttonTarget.textContent = "Copied!"
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => (this.buttonTarget.textContent = "Copy"), 2000)
  }
}
