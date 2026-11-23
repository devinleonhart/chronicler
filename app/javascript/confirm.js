// Asks with the layout's dialog instead of the browser's.
import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = (message, form) => {
  const dialog = document.getElementById("confirm_dialog")
  dialog.querySelector("#confirm_title").textContent = form.dataset.confirmTitle || "Are you sure?"
  dialog.querySelector("[data-confirm=message]").textContent = message
  dialog.querySelector("[data-confirm=accept]").textContent = form.dataset.confirmAccept || "Continue"
  dialog.returnValue = "cancel"
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}
