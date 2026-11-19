import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["label", "submit", "clock", "ring"]
  static values = { locksAt: String, opensAt: String, live: Boolean, refreshUrl: String }

  connect() {
    if (!this.liveValue) return
    this.deadline = new Date(this.locksAtValue).getTime()
    this.window = this.deadline - new Date(this.opensAtValue).getTime()
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
    clearTimeout(this.refreshTimer)
  }

  tick() {
    const remaining = this.deadline - Date.now()
    if (remaining <= 0) return this.lock()
    if (this.hasLabelTarget) this.labelTarget.textContent = `Locks in ${this.format(remaining)}`
    if (this.hasClockTarget) this.clockTarget.textContent = this.clock(remaining)
    this.drainRings(remaining)
  }

  lock() {
    clearInterval(this.timer)
    if (this.hasLabelTarget) this.labelTarget.textContent = "Betting closed"
    if (this.hasClockTarget) this.clockTarget.textContent = "0:00"
    this.drainRings(0)
    this.element.classList.add("is-locked")
    this.submitTargets.forEach((button) => {
      button.disabled = true
      button.value = "Betting closed"
    })
    if (this.hasRefreshUrlValue) this.refreshTimer = setTimeout(() => this.refresh(), 800)
  }

  drainRings(remaining) {
    const left = this.window > 0 ? Math.min(Math.max(remaining / this.window, 0), 1) : 0
    this.ringTargets.forEach((ring) => {
      ring.querySelector(".bet-pad__ring-fill").style.strokeDashoffset = 100 * (1 - left)
      ring.classList.toggle("is-ending", remaining <= 10_000)
    })
  }

  async refresh() {
    try {
      const response = await fetch(this.refreshUrlValue, { headers: { Accept: "text/vnd.turbo-stream.html" } })
      if (response.ok) Turbo.renderStreamMessage(await response.text())
    } catch {
    }
  }

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
