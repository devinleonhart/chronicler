import { Controller } from "@hotwired/stimulus"

// Opens when its frame loads a form, and empties the frame when closed.
export default class extends Controller {
  static targets = ["frame"]

  open() {
    if (!this.element.open && this.frameTarget.children.length > 0) this.element.showModal()
  }

  close() {
    this.element.close()
  }

  clear() {
    this.frameTarget.removeAttribute("src")
    this.frameTarget.replaceChildren()
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }
}
