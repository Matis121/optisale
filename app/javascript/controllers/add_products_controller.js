import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { orderId: Number }
  
  connect() {
  }

  async addProducts() {
    const selectedProducts = JSON.parse(localStorage.getItem('selectedProducts') || '[]')
    
    if (selectedProducts.length === 0) {
      alert('Nie wybrano żadnych produktów')
      return
    }

    const button = this.element
    const originalText = button.innerHTML
    button.disabled = true
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Dodawanie...'

    try {
      // Add each product to the order
      for (const product of selectedProducts) {
        await this.addProductToOrder(product)
      }

      // Clear selected products
      localStorage.removeItem('selectedProducts')
      
      // Close modal
      const modal = document.getElementById('order_add_product_modal')
      if (modal) {
        modal.close()
      }

      // Reload the page to show updated products
      window.location.reload()
    } catch (error) {
      console.error('Error adding products:', error)
      alert('Wystąpił błąd podczas dodawania produktów')
    } finally {
      button.disabled = false
      button.innerHTML = originalText
    }
  }

  async addProductToOrder(product) {
    const formData = new FormData()
    formData.append('order_product[order_id]', this.orderIdValue)
    formData.append('order_product[product_id]', product.id)
    formData.append('order_product[quantity]', product.quantity)

    const response = await fetch('/order_products', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })

    const result = await response.json()

    if (!response.ok || !result.success) {
      const errorMessage = result.errors ? result.errors.join(', ') : 'Błąd podczas dodawania produktu'
      throw new Error(errorMessage)
    }

    return result
  }
} 