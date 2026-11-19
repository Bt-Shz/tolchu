import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video", "soundButton"]
  static values = { freezeAt: Number, revealed: Boolean }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => entries.forEach((entry) => (entry.isIntersecting ? this.play() : this.pause())),
      { threshold: 0.6 }
    )
    this.observer.observe(this.element)
    this.watchFrames()
  }

  disconnect() {
    this.observer?.disconnect()
    if (this.frameHandle && this.videoTarget.cancelVideoFrameCallback) {
      this.videoTarget.cancelVideoFrameCallback(this.frameHandle)
    }
  }

  play() {
    if (this.isFrozen) return
    this.videoTarget.play().catch(() => {})
  }

  pause() {
    this.videoTarget.pause()
  }

  replay() {
    this.element.classList.remove("is-frozen")
    this.videoTarget.currentTime = 0
    this.videoTarget.play().catch(() => {})
  }

  toggleSound() {
    this.videoTarget.muted = !this.videoTarget.muted
    this.soundButtonTarget.textContent = this.videoTarget.muted ? "🔇" : "🔊"
    this.soundButtonTarget.setAttribute("aria-label", this.videoTarget.muted ? "Unmute clip" : "Mute clip")
  }

  enforceFreeze() {
    if (this.revealedValue || this.freezeAtValue <= 0) return
    if (this.videoTarget.currentTime >= this.freezeAtValue) this.freeze()
  }

  ended() {
    if (this.revealedValue) this.element.classList.add("is-ended")
  }

  watchFrames() {
    const video = this.videoTarget
    if (!video.requestVideoFrameCallback) return

    const check = (_now, metadata) => {
      if (!this.revealedValue && this.freezeAtValue > 0 && metadata.mediaTime >= this.freezeAtValue) this.freeze()
      this.frameHandle = video.requestVideoFrameCallback(check)
    }
    this.frameHandle = video.requestVideoFrameCallback(check)
  }

  freeze() {
    const video = this.videoTarget
    video.pause()
    if (Math.abs(video.currentTime - this.freezeAtValue) > 0.05) video.currentTime = this.freezeAtValue
    this.element.classList.add("is-frozen")
  }

  get isFrozen() {
    return this.element.classList.contains("is-frozen")
  }
}
