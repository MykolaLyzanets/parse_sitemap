import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showPanel(this.tabTargets.find((tab) => tab.getAttribute("aria-selected") === "true")?.dataset.panel || "added")
  }

  select(event) {
    const panelName = event.currentTarget.dataset.panel
    this.showPanel(panelName)
  }

  showPanel(panelName) {
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.panel === panelName
      tab.setAttribute("aria-selected", active ? "true" : "false")
      tab.classList.toggle("is-active", active)
    })

    this.panelTargets.forEach((panel) => {
      const active = panel.dataset.panel === panelName
      panel.classList.toggle("is-hidden", !active)
    })
  }
}
