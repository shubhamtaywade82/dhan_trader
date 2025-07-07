// app/javascript/controllers/recommendations_controller.js

import { Controller } from "@hotwired/stimulus"
import { csrfToken } from "@rails/ujs"

export default class extends Controller {
  static targets = ["template", "container", "symbol", "signals", "explanation"]

  connect() {
    this.load()
  }

  load() {
    fetch("/api/recommendations?style=intraday")
      .then(response => response.json())
      .then(data => {
        this.containerTarget.innerHTML = ""

        Object.values(data).forEach(instrumentRecs => {
          const latest = instrumentRecs[0]

          const clone = this.templateTarget.content.cloneNode(true)
          clone.querySelector("[data-recommendations-target='symbol']").textContent = latest.instrument
          clone.querySelector("[data-recommendations-target='explanation']").textContent = latest.explanation

          const signalsList = clone.querySelector("[data-recommendations-target='signals']")
          latest.signals.forEach(sig => {
            const li = document.createElement("li")
            li.textContent = `${sig.indicator}: ${sig.signal} (${sig.value})`
            signalsList.appendChild(li)
          })

          clone.querySelector("button").dataset.symbol = latest.instrument

          this.containerTarget.appendChild(clone)
        })
      })
  }

  placeOrder(event) {
    const symbol = event.target.dataset.symbol
    // Call your DhanHQ integration:
    fetch("/orders", {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken(),
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        instrument_symbol: symbol,
        order_type: "BUY",
        quantity: 1
      })
    })
    .then(res => res.json())
    .then(data => {
      alert(`Order placed: ${data.status}`)
    })
  }
}
