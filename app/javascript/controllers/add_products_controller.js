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
    formData.append('product[order_id]', this.orderIdValue)
    formData.append('product[product_id]', product.id)
    formData.append('product[quantity]', product.quantity)

    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

    const response = await fetch(`/orders/${this.orderIdValue}/products`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': csrfToken
      },
      body: formData
    })

    const result = await response.json()

    if (!response.ok || !result.success) {
      const errorMessage = result.errors ? result.errors.join(', ') : 'Błąd podczas dodawania produktu'
      throw new Error(errorMessage)
    }

    return result
  }
} 