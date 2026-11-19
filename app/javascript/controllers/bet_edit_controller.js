import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "review", "editor" ]

  open() {
    this.reviewTarget.hidden = true
    this.editorTarget.hidden = false
    this.editorTarget.querySelector(".bet-pad__button")?.focus({ preventScroll: true })
  }

  close() {
    this.editorTarget.hidden = true
    this.reviewTarget.hidden = false
  }
}
