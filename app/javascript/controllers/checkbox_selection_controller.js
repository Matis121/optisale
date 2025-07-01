// app/javascript/controllers/checkbox_selection_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["child", "selectionInput", "counter", "form"]
  
  connect() {
    this.loadSelection()

    this.element.addEventListener("turbo:frame-load", () => {
      this.loadSelection()
    })
  }

  updateSelection(e) {
    const checkbox = e.target
    const tr = checkbox.closest("tr")
    let selection = this.selection

    if (checkbox.checked) {
      if (!selection.includes(checkbox.value)) {
        selection.push(checkbox.value)
      }
      tr.classList.add("bg-blue-100")
    } else {
      selection = selection.filter(id => id !== checkbox.value)
      tr.classList.remove("bg-blue-100")
    }

    this.selection = selection
    this.updateCounter()
  }

  selectAllOnPage() {
    let selection = this.selection
    this.childTargets.forEach(cb => {
      cb.checked = true
      if (!selection.includes(cb.value)) {
        selection.push(cb.value)
      }
      const tr = cb.closest("tr")
      tr.classList.add("bg-blue-100")
    })
    this.selection = selection
    this.updateCounter()
  }

  deselectAll() {
    this.childTargets.forEach(cb => {
      cb.checked = false
      const tr = cb.closest("tr")
      tr.classList.remove("bg-blue-100")
    })
    this.selection = []
    this.updateCounter()
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.selection.length
      this.counterTarget.classList.toggle("hidden", this.selection.length === 0)
    }
  }

  loadSelection() {
    this.selection = JSON.parse(this.selectionInputTarget.value || "[]")
    this.childTargets.forEach(cb => {
      cb.checked = this.selection.includes(cb.value)
      const tr = cb.closest("tr")
      tr.classList.toggle("bg-blue-100", this.selection.includes(cb.value))
    })
    this.updateCounter()
  }

  clearCheckboxes() {
    this.childTargets.forEach(cb => {
      cb.checked = false
      const tr = cb.closest("tr")
      tr.classList.remove("bg-blue-100")
      tr.classList.add("opacity-40")
    })
    this.selection = []
    this.updateCounter()
  }

  get selection() {
    return JSON.parse(this.selectionInputTarget.value || "[]")
  }

  set selection(value) {
    this.selectionInputTarget.value = JSON.stringify(value)
  }
}
