import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["productSearch"]

  clearSelection() {
    localStorage.removeItem('selectedProducts')
    
    const productSearchController = this.application.getControllerForElementAndIdentifier(this.element, 'product-search')
    if (productSearchController) {
      productSearchController.updateSelectedProductsSummary()
    }
  }
} 