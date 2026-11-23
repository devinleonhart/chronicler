import { Controller } from "@hotwired/stimulus"

// Narrows a list of checkboxes to those whose label contains the query.
export default class extends Controller {
  static targets = ["query", "item", "empty"]

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    let shown = 0
    this.itemTargets.forEach((item) => {
      const match = item.textContent.toLowerCase().includes(query)
      item.classList.toggle("hidden", !match)
      if (match) shown += 1
    })
    this.emptyTarget.classList.toggle("hidden", shown > 0)
  }

  // Enter in the search would submit the form around it.
  ignore() {}
}
