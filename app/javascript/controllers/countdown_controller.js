import { Controller } from "@hotwired/stimulus"

// Ticks down to a market's lock time. When it hits zero the card switches to
// "Betting closed" and the bet button is disabled. The server enforces the lock
// regardless; this just keeps the UI honest. A pending bet's review screen shows
// the same countdown as a bare clock in the bet button's slot.
export default class extends Controller {
  static targets = ["label", "submit", "clock"]
  static values = { locksAt: String, live: Boolean }

  connect() {
    if (!this.liveValue) return
    this.deadline = new Date(this.locksAtValue).getTime()
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const remaining = this.deadline - Date.now()
    if (remaining <= 0) return this.lock()
    if (this.hasLabelTarget) this.labelTarget.textContent = `Locks in ${this.format(remaining)}`
    if (this.hasClockTarget) this.clockTarget.textContent = this.clock(remaining)
  }

  lock() {
    clearInterval(this.timer)
    if (this.hasLabelTarget) this.labelTarget.textContent = "Betting closed"
    if (this.hasClockTarget) this.clockTarget.textContent = "locked"
    this.element.classList.add("is-locked")
    this.submitTargets.forEach((button) => {
      button.disabled = true
      button.value = "Betting closed"
    })
  }

  // m:ss, or h:mm:ss past an hour (same as ApplicationHelper#lock_clock).
  clock(ms) {
    const total = Math.ceil(ms / 1000)
    const hours = Math.floor(total / 3600)
    const minutes = Math.floor((total % 3600) / 60)
    const seconds = String(total % 60).padStart(2, "0")
    return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${seconds}` : `${minutes}:${seconds}`
  }

  format(ms) {
    const total = Math.ceil(ms / 1000)
    const days = Math.floor(total / 86400)
    const hours = Math.floor((total % 86400) / 3600)
    const minutes = Math.floor((total % 3600) / 60)
    const seconds = total % 60
    if (days > 0) return `${days}d ${hours}h`
    if (hours > 0) return `${hours}h ${minutes}m`
    return `${minutes}:${String(seconds).padStart(2, "0")}`
  }
}
