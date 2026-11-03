import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close(event) {
    event?.preventDefault()
    this.element.closest("turbo-frame")?.replaceChildren()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close(event)
  }

  backdropClick(event) {
    if (event.target === event.currentTarget) this.close(event)
  }
}
