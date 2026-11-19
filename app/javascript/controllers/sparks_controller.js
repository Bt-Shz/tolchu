import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "tolchu:last-session-net"
const SPARK_COUNT = 9

export default class extends Controller {
  static values = { value: Number }

  connect() {
    const previous = this.read()
    this.write(this.valueValue)
    if (previous !== null && this.valueValue > previous) this.burst()
  }

  burst() {
    this.element.classList.remove("is-sparking")
    void this.element.offsetWidth
    this.element.classList.add("is-sparking")
    for (let i = 0; i < SPARK_COUNT; i++) {
      const spark = document.createElement("span")
      spark.className = "spark"
      spark.setAttribute("aria-hidden", "true")
      spark.style.setProperty("--angle", `${(360 / SPARK_COUNT) * i + Math.random() * 24}deg`)
      spark.style.setProperty("--reach", `${10 + Math.random() * 10}px`)
      spark.style.animationDelay = `${Math.random() * 80}ms`
      spark.addEventListener("animationend", () => spark.remove())
      this.element.appendChild(spark)
    }
  }

  read() {
    try {
      const stored = sessionStorage.getItem(STORAGE_KEY)
      return stored === null ? null : Number(stored)
    } catch {
      return null
    }
  }

  write(value) {
    try {
      sessionStorage.setItem(STORAGE_KEY, String(value))
    } catch {
    }
  }
}
