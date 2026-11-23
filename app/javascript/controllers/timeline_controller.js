import { Controller } from "@hotwired/stimulus"

const YEAR = 1000 * 60 * 60 * 24 * 365

// vis-timeline renders content and titles as HTML.
const escape = (text) => {
  const element = document.createElement("span")
  element.textContent = text
  return element.innerHTML
}

export default class extends Controller {
  static values = { items: Array, start: String, end: String, current: String }

  async connect() {
    const { Timeline } = await import("vis-timeline")
    if (!this.element.isConnected || this.timeline) return

    this.timeline = new Timeline(this.element, this.itemsValue.map((item) => this.build(item)), this.options())
    this.timeline.addCustomTime(new Date(this.currentValue), "currentDay")
    this.timeline.on("select", ({ items }) => this.edit(items[0]))
  }

  disconnect() {
    this.timeline?.destroy()
    this.timeline = null
  }

  build(item) {
    const dates = item.end ? `${item.start} – ${item.end}` : item.start
    return {
      id: item.id,
      content: escape(item.name),
      start: item.start,
      end: item.end ?? undefined,
      type: item.end ? "range" : "box",
      title: `${escape(item.name)}<br>${dates}`,
      className: item.currentDay ? "item-current-day" : "item-event"
    }
  }

  options() {
    return {
      min: this.startValue,
      max: this.endValue,
      start: this.startValue,
      end: this.endValue,
      stack: true,
      showMajorLabels: true,
      showMinorLabels: true,
      orientation: { axis: "top" },
      zoomMin: YEAR,
      tooltip: { followMouse: true, overflowMethod: "flip" },
      selectable: true
    }
  }

  edit(id) {
    if (id === undefined) return

    document.getElementById("dialog").src = this.itemsValue.find((item) => item.id === id).url
    // Lets the same item be chosen again.
    this.timeline.setSelection([])
  }
}
