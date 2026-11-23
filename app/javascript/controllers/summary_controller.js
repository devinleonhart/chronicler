import { Controller } from "@hotwired/stimulus"

// Chooses the characters of a summary, singly or by group.
export default class extends Controller {
  static targets = ["ids", "query", "clear", "groups", "group", "character", "generate", "output", "placeholder"]

  connect() {
    this.update()
  }

  update() {
    const selected = this.characterTargets.filter((box) => box.checked)
    this.idsTarget.value = selected.map((box) => box.value).join(",")
    this.generateTarget.disabled = selected.length === 0
    this.clearTarget.textContent = `Clear (${selected.length})`
    this.clearTarget.classList.toggle("hidden", selected.length === 0)
    this.groupTargets.forEach((chip) => chip.setAttribute("aria-pressed", this.state(chip)))
    if (this.hasGroupsTarget) this.groupsTarget.classList.toggle("hidden", this.queryTarget.value !== "")
  }

  toggleGroup({ currentTarget }) {
    const select = this.state(currentTarget) !== "true"
    this.members(currentTarget).forEach((box) => (box.checked = select))
    this.update()
  }

  clear() {
    this.characterTargets.forEach((box) => (box.checked = false))
    this.outputTarget.removeAttribute("src")
    this.outputTarget.replaceChildren(this.placeholderTarget.content.cloneNode(true))
    this.update()
  }

  state(chip) {
    const members = this.members(chip)
    const count = members.filter((box) => box.checked).length
    if (count === 0) return "false"
    return count === members.length ? "true" : "mixed"
  }

  members(chip) {
    return this.characterTargets.filter((box) => JSON.parse(box.dataset.groups).includes(Number(chip.dataset.group)))
  }
}
