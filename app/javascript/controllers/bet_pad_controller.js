import { Controller } from "@hotwired/stimulus"

const ANGLES = { r: 0, ur: 45, u: 90, ul: 135, l: 180, dl: 225, d: 270, dr: 315 }
const HOLD_DELAY_MS = 250
const FAST_RAMP_AFTER_MS = 1500
const FLICK_DISTANCE_PX = 24
const FLICK_MIN_SPEED = 0.2
const HAPTICS = { raise: 8, lower: [ 5, 25, 5 ], modeRaise: 10, modeLower: [ 6, 40, 6 ], fire: 20 }

export default class extends Controller {
  static targets = [ "section", "input", "button", "stakeLabel", "modeLabel", "modeButton" ]
  static values = { pools: Object, totalPool: Number, rakeRate: Number, min: Number, max: Number }

  connect() {
    this.mode = 1
    this.element.classList.add("is-enhanced")
    this.render()
  }

  disconnect() {
    this.stopRamp()
    clearTimeout(this.hintTimer)
  }

  get stake() {
    const value = parseInt(this.inputTarget.value, 10)
    return Number.isFinite(value) ? value : this.minValue
  }

  set stake(value) {
    this.inputTarget.value = Math.max(this.minValue, Math.min(this.maxValue, value))
  }

  setMode({ params: { mode } }) {
    this.mode = mode
    buzz(mode > 0 ? HAPTICS.modeRaise : HAPTICS.modeLower)
    this.render()
  }

  startRamp() {
    this.ramping = true
    const startedAt = Date.now()
    this.rampTimer = setInterval(() => {
      const step = Date.now() - startedAt < FAST_RAMP_AFTER_MS ? 1 : 5
      const before = this.stake
      this.stake = before + this.mode * step
      if (this.stake !== before) buzz(this.mode > 0 ? HAPTICS.raise : HAPTICS.lower)
      this.render()
    }, this.mode > 0 ? 100 : 140)
    this.render()
  }

  stopRamp() {
    clearTimeout(this.holdTimer)
    clearInterval(this.rampTimer)
    this.ramping = false
  }

  press(event) {
    if (this.waiting || event.button > 0) return
    this.buttonTarget.setPointerCapture?.(event.pointerId)
    const point = { x: event.clientX, y: event.clientY, t: event.timeStamp }
    this.gesture = { start: point, samples: [ point ], direction: null, peakSpeed: 0 }
    this.holdTimer = setTimeout(() => this.startRamp(), HOLD_DELAY_MS)
  }

  drag(event) {
    const gesture = this.gesture
    if (!gesture) return
    const point = { x: event.clientX, y: event.clientY, t: event.timeStamp }
    this.trackSpeed(gesture, point)
    gesture.samples.push(point)
    if (gesture.samples.length > 8) gesture.samples.shift()

    const dx = point.x - gesture.start.x
    const dy = point.y - gesture.start.y
    if (Math.hypot(dx, dy) > FLICK_DISTANCE_PX) {
      this.stopRamp()
      gesture.direction = this.nearestDirection(dx, dy)
    } else {
      gesture.direction = null
    }
    this.render()
  }

  release(event) {
    const gesture = this.gesture
    if (!gesture) return
    this.gesture = null
    const wasRamping = this.ramping
    this.stopRamp()

    if (gesture.direction) {
      this.trackSpeed(gesture, { x: event.clientX, y: event.clientY, t: event.timeStamp })
      if (gesture.peakSpeed >= FLICK_MIN_SPEED) return this.fire(gesture.direction)
      this.showHint("Flick to bet")
    } else if (!wasRamping) {
      this.step()
    }
    this.render()
  }

  cancel() {
    this.gesture = null
    this.stopRamp()
    this.render()
  }

  suppress(event) {
    event.preventDefault()
  }

  key(event) {
    const steps = { ArrowUp: 1, ArrowRight: 1, ArrowDown: -1, ArrowLeft: -1 }
    if (event.key in steps) {
      event.preventDefault()
      this.stake = this.stake + steps[event.key]
      this.render()
    } else if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      const selected = this.selectedSection
      selected ? this.fire(selected.dataset.dir) : this.showHint("Pick an outcome first")
    }
  }

  nearestDirection(dx, dy) {
    let angle = (Math.atan2(-dy, dx) * 180) / Math.PI
    if (angle < 0) angle += 360
    let best = null
    let bestGap = Infinity
    for (const section of this.sectionTargets) {
      const raw = Math.abs(angle - ANGLES[section.dataset.dir])
      const gap = Math.min(raw, 360 - raw)
      if (gap < bestGap) {
        bestGap = gap
        best = section.dataset.dir
      }
    }
    return best
  }

  trackSpeed(gesture, point) {
    const from = gesture.samples.findLast((sample) => point.t - sample.t >= 30)
    if (!from) return
    const speed = Math.hypot(point.x - from.x, point.y - from.y) / (point.t - from.t)
    gesture.peakSpeed = Math.max(gesture.peakSpeed, speed)
  }

  step() {
    const before = this.stake
    this.stake = before + this.mode
    if (this.stake !== before) buzz(this.mode > 0 ? HAPTICS.raise : HAPTICS.lower)
  }

  fire(direction) {
    const section = this.sectionTargets.find((candidate) => candidate.dataset.dir === direction)
    if (!section || this.waiting) return
    section.querySelector("input[type=radio]").checked = true
    this.waiting = true
    buzz(HAPTICS.fire)
    this.render()
    this.element.requestSubmit()
  }

  submitted(event) {
    if (event.detail.success) return
    this.waiting = false
    this.render()
  }

  render() {
    const stake = this.stake
    this.stakeLabelTarget.textContent = stake
    this.modeLabelTarget.textContent = `${this.mode > 0 ? "▲" : "▼"} ${this.ramping ? (this.mode > 0 ? "raising" : "lowering") : "hold"}`
    this.buttonTarget.setAttribute("aria-label",
      `Stake ${stake} credits. Flick toward an outcome to bet, hold to change the stake, or use the arrow keys.`)
    this.modeButtonTargets.forEach((button) => {
      const on = Number(button.dataset.betPadModeParam) === this.mode
      button.classList.toggle("is-on", on)
      button.setAttribute("aria-pressed", on)
    })
    this.element.classList.toggle("is-waiting", Boolean(this.waiting))
    this.element.classList.toggle("is-lowering", this.mode < 0)

    const aimed = this.gesture?.direction
    this.sectionTargets.forEach((section) => {
      const radio = section.querySelector("input[type=radio]")
      const { multiple, payout } = this.estimate(radio.value, stake)
      section.querySelector(".outcome__odds").textContent = `×${multiple.toFixed(2)}`
      section.querySelector(".outcome__wins").textContent = `wins ${payout.toLocaleString()}`
      section.classList.toggle("is-aimed", section.dataset.dir === aimed)
      section.classList.toggle("is-selected", radio.checked)
    })
  }

  estimate(outcomeId, stake) {
    const outcomePool = (this.poolsValue[outcomeId] || 0) + stake
    const total = this.totalPoolValue + stake
    const losing = total - outcomePool
    if (losing === 0) return { multiple: 1, payout: stake }
    const rake = Math.min(Math.floor(total * this.rakeRateValue), losing)
    return { multiple: (total - rake) / outcomePool, payout: Math.floor(((total - rake) * stake) / outcomePool) }
  }

  showHint(text) {
    const hint = this.element.closest(".clip-card")?.querySelector(".bet-pad__hint")
    if (!hint) return
    clearTimeout(this.hintTimer)
    hint.textContent = text
    hint.classList.add("is-visible")
    this.hintTimer = setTimeout(() => hint.classList.remove("is-visible"), 1600)
  }

  get selectedSection() {
    return this.sectionTargets.find((section) => section.querySelector("input[type=radio]").checked)
  }

  labelOf(section) {
    return section.querySelector(".outcome__label").textContent.trim()
  }
}

function buzz(pattern) {
  navigator.vibrate?.(pattern)
}
