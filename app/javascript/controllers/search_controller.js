import { Controller } from "@hotwired/stimulus"

// Submits a search form shortly after typing stops.
export default class extends Controller {
  disconnect() {
    clearTimeout(this.timeout)
  }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), 300)
  }
}
