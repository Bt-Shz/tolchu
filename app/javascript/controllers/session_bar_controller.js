import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "segment" ]
  static values = { size: Number }

  connect() {
    const count = this.segmentTargets.length
    const current = this.segmentTargets.findIndex((segment) => segment.querySelector("[aria-current]"))
    const last = current >= 0 ? current : count - 1
    this.start = this.wrap(last - this.sizeValue + 1)
    this.render()
  }

  previous() {
    this.start = this.wrap(this.start - 1)
    this.render()
  }

  next() {
    this.start = this.wrap(this.start + 1)
    this.render()
  }

  render() {
    const count = this.segmentTargets.length
    if (count <= this.sizeValue) return
    this.segmentTargets.forEach((segment) => { segment.hidden = true })
    for (let i = 0; i < this.sizeValue; i++) {
      const segment = this.segmentTargets[this.wrap(this.start + i)]
      segment.hidden = false
      segment.style.order = i
    }
  }

  wrap(index) {
    const count = this.segmentTargets.length
    return ((index % count) + count) % count
  }
}
