import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "actions"]
  static classes = ["loading"]
  
  connect() {
    this.showTabFromHash() || this.showTab(0)
    this.showActions()
    this.element.classList.remove(this.loadingClass)
    window.addEventListener("hashchange", this.handleHashChange)
  }

  disconnect() {
    window.removeEventListener("hashchange", this.handleHashChange)
  }

  handleHashChange = () => {
    this.showTabFromHash()
  }

  switch(event) {
    event.preventDefault()
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.showTab(index)
    this.updateHash(index)
  }

  showTabFromHash() {
    const hash = window.location.hash.slice(1)
    if (!hash) return false

    const index = this.panelTargets.findIndex(el => el.id === hash)
    if (index === -1) return false

    this.showTab(index)
    return true
  }

  updateHash(index) {
    const panel = this.panelTargets[index]
    if (panel?.id) {
      history.replaceState(null, null, `#${panel.id}`)
    }
  }

  showTab(index) {
    this.tabTargets.forEach((el, i) => {
      if (i === index) {
        el.classList.add("tab-active")
      } else {
        el.classList.remove("tab-active")
      }
    })

    this.panelTargets.forEach((el, i) => {
      if (i === index) {
        el.classList.remove("hidden")
        // Re-trigger animation
        el.style.animation = "none"
        el.offsetHeight // force reflow
        el.style.animation = null
      } else {
        el.classList.add("hidden")
      }
    })
  }

  showActions() {
    if (!this.hasActionsTarget) return
      this.actionsTarget.classList.remove("hidden")
      this.actionsTarget.style.animation = "none"
      this.actionsTarget.offsetHeight
      this.actionsTarget.style.animation = null
  }
}
