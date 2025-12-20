import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "productsList", 
    "searchInput", 
    "catalogFilter", 
    "selectedList",
    "addButton",
    "pagination",
    "mainContent",
    "leftPanel",
    "rightPanel"
  ]
  
  static values = {
    searchDelay: { type: Number, default: 300 },
    storageKey: { type: String, default: "selectedProducts" },
    currentPage: { type: Number, default: 1 },
    perPage: { type: Number, default: 20 },
    orderId: { type: Number, required: true }
  }

  connect() {
    this.searchTimeout = null
    this.renderPagination(null) // Show loading state
    this.initializeLayout()
    this.updateSelectedProductsSummary() // Check if there are already selected products
    this.loadProducts()
  }

  disconnect() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }

  // Initialize layout
  initializeLayout() {
    if (this.hasLeftPanelTarget) {
      // Remove flex-1 and add w-full for full width
      this.leftPanelTarget.classList.remove('flex-1')
      this.leftPanelTarget.classList.add('w-full')
    }
    if (this.hasRightPanelTarget) {
      this.rightPanelTarget.classList.add('hidden')
    }
  }

  // Search input handler with debouncing
  search() {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      this.loadProducts()
    }, this.searchDelayValue)
  }

  // Catalog filter change handler
  filter() {
    this.loadProducts()
  }

  // Load products from server
  async loadProducts(page = 1) {
    const query = this.searchInputTarget?.value || ""
    const catalogId = this.catalogFilterTarget?.value || ""
    
    try {
      const response = await fetch(`/orders/${this.orderIdValue}/search_products?query=${encodeURIComponent(query)}&catalog_id=${encodeURIComponent(catalogId)}&page=${page}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      const data = await response.json()
      
      this.renderProducts(data.products, data.pagination)
    } catch (error) {
      console.error("Error loading products:", error)
      this.showError("Błąd podczas ładowania produktów")
    }
  }

  // Render products list
  renderProducts(products, pagination = null) {
    if (!this.hasProductsListTarget) return

    this.productsListTarget.innerHTML = ""

    if (products.length === 0) {
      this.productsListTarget.innerHTML = `
        <div class="text-center py-8 text-base-content/60">
          <i class="fas fa-search text-3xl mb-4"></i>
          <p>Nie znaleziono produktów</p>
        </div>
      `
    } else {
      products.forEach(product => {
        const productElement = this.createProductElement(product)
        this.productsListTarget.appendChild(productElement)
      })
    }

    // Always render pagination
    this.renderPagination(pagination)
  }

  // Create individual product element
  createProductElement(product) {
    const template = document.getElementById('product_item_template')
    if (!template) {
      console.error("Product template not found")
      return document.createElement('div')
    }

    const clone = template.content.cloneNode(true)
    
    const productItem = clone.querySelector('.product-item')
    if (productItem) {
      productItem.dataset.productId = product.id
    }
    
    // Set product data
    this.setElementText(clone, '.product-name', product.name)
    this.setElementText(clone, '.product-sku', product.sku || '-')
    this.setElementText(clone, '.product-ean', product.ean || '-')
    this.setElementText(clone, '.product-price', `${product.gross_price} PLN`)
    this.setElementText(clone, '.product-stock', product.stock || 0)
    
    // Setup add button
    const addButton = clone.querySelector('.add-product-btn')
    if (addButton) {
      addButton.dataset.productId = product.id
      addButton.dataset.action = "click->product-search#addProduct"
      addButton.dataset.productIdParam = product.id
    }
    
    return clone
  }

  // Helper to set element text safely
  setElementText(clone, selector, text) {
    const element = clone.querySelector(selector)
    if (element) {
      element.textContent = text
    }
  }

  // Add product to selection
  addProduct(event) {
    const productId = event.params.productId
    const productElement = event.target.closest('.product-item')
    const quantityInput = productElement?.querySelector('[data-product-quantity]')
    const quantity = parseInt(quantityInput?.value || 1)
    
    // Get product data from the element
    const product = this.getProductDataFromElement(productElement)
    if (!product) return
    
    this.addProductToStorage(product, quantity)
    this.updateSelectedProductsSummary()
    this.showAddSuccess(event.currentTarget)
  }

  // Get product data from DOM element
  getProductDataFromElement(productElement) {
    if (!productElement) return null

    const name = productElement.querySelector('.product-name')?.textContent
    const sku = productElement.querySelector('.product-sku')?.textContent
    const ean = productElement.querySelector('.product-ean')?.textContent
    const priceText = productElement.querySelector('.product-price')?.textContent
    const price = parseFloat(priceText?.replace(' PLN', '') || 0)
    const id = productElement.dataset.productId

    return { id, name, sku, ean, gross_price: price }
  }

  // Add product to localStorage
  addProductToStorage(product, quantity) {
    const selectedProducts = this.getSelectedProducts()
    const existingIndex = selectedProducts.findIndex(p => p.id === product.id)
    
    if (existingIndex >= 0) {
      selectedProducts[existingIndex].quantity += quantity
    } else {
      selectedProducts.push({
        ...product,
        quantity: quantity
      })
    }
    
    localStorage.setItem(this.storageKeyValue, JSON.stringify(selectedProducts))
  }

  // Get selected products from localStorage
  getSelectedProducts() {
    return JSON.parse(localStorage.getItem(this.storageKeyValue) || '[]')
  }

  // Show success feedback on add button
  showAddSuccess(element) {
    // In Stimulus actions, event.target can be the inner <i>, while event.currentTarget is the <button>.
    // We always want to update the button itself to avoid rendering both icons at once.
    const button = element?.closest?.('button') || element
    if (!button) return

    const originalText = button.innerHTML
    button.innerHTML = '<i class="fas fa-check"></i>'
    button.classList.add('btn-success')
    button.classList.remove('btn-primary')
    
    setTimeout(() => {
      button.innerHTML = originalText
      button.classList.remove('btn-success')
      button.classList.add('btn-primary')
    }, 1000)
  }

  // Update selected products summary
  updateSelectedProductsSummary() {
    const selectedProducts = this.getSelectedProducts()
    
    if (selectedProducts.length === 0) {
      // Hide right panel and make left panel full width
      if (this.hasRightPanelTarget) {
        this.rightPanelTarget.classList.add('hidden')
      }
      if (this.hasLeftPanelTarget) {
        this.leftPanelTarget.classList.remove('flex-1')
        this.leftPanelTarget.classList.add('w-full')
      }
      return
    }
    
    // Show right panel and make left panel flexible
    if (this.hasRightPanelTarget) {
      this.rightPanelTarget.classList.remove('hidden')
    }
    if (this.hasLeftPanelTarget) {
      this.leftPanelTarget.classList.remove('w-full')
      this.leftPanelTarget.classList.add('flex-1')
    }
    
    this.renderSelectedProducts(selectedProducts)
  }

  // Render selected products list
  renderSelectedProducts(selectedProducts) {
    if (!this.hasSelectedListTarget) return

    this.selectedListTarget.innerHTML = ""
    
    selectedProducts.forEach(product => {
      const productElement = this.createSelectedProductElement(product)
      this.selectedListTarget.appendChild(productElement)
    })
  }

  // Create selected product element
  createSelectedProductElement(product) {
    const productElement = document.createElement('div')
    productElement.className = 'flex items-center justify-between p-2 bg-base-100 rounded'
    productElement.innerHTML = `
      <div>
        <div class="font-medium">${product.name}</div>
        <div class="text-sm text-base-content/60">Ilość: ${product.quantity} • Cena: ${product.gross_price} PLN</div>
      </div>
      <button class="btn btn-ghost btn-xs text-error" data-action="click->product-search#removeSelectedProduct" data-product-search-product-id-param="${product.id}">
        <i class="fas fa-times"></i>
      </button>
    `
    return productElement
  }

  // Remove selected product
  removeSelectedProduct(event) {
    const productId = parseInt(event.params.productId)
    const selectedProducts = this.getSelectedProducts()
    
    const filtered = selectedProducts.filter(p => {
      const pId = parseInt(p.id)
      return pId !== productId
    })
    
    localStorage.setItem(this.storageKeyValue, JSON.stringify(filtered))
    this.updateSelectedProductsSummary()
  }

  // Clear all selected products
  clearSelection() {
    localStorage.removeItem(this.storageKeyValue)
    this.updateSelectedProductsSummary()
  }

  // Render pagination controls
  renderPagination(pagination) {
    if (!this.hasPaginationTarget) return
    
    if (!pagination) {
      this.paginationTarget.innerHTML = `
        <div class="text-center text-sm text-base-content/60">
          Ładowanie...
        </div>
      `
      return
    }
    
    const prevDisabled = !pagination.has_prev ? 'disabled' : ''
    const nextDisabled = !pagination.has_next ? 'disabled' : ''
    const prevClass = !pagination.has_prev ? 'btn-disabled opacity-50' : ''
    const nextClass = !pagination.has_next ? 'btn-disabled opacity-50' : ''
    
    let paginationHTML = `
      <div class="flex justify-between items-center">
        <div class="text-sm text-base-content/60">
          Strona ${pagination.current_page} z ${pagination.total_pages} (${pagination.total_count} produktów)
        </div>
        <div class="flex gap-2">
          <button class="btn btn-sm btn-ghost ${prevClass}" 
                  data-action="click->product-search#loadPage" 
                  data-page="${pagination.current_page - 1}"
                  ${prevDisabled}>
            <i class="fas fa-chevron-left"></i>
          </button>
          <button class="btn btn-sm btn-ghost ${nextClass}" 
                  data-action="click->product-search#loadPage" 
                  data-page="${pagination.current_page + 1}"
                  ${nextDisabled}>
            <i class="fas fa-chevron-right"></i>
          </button>
        </div>
      </div>
    `
    
    this.paginationTarget.innerHTML = paginationHTML
  }

  // Load specific page
  loadPage(event) {
    const button = event.target.closest('button')
    if (button.disabled) return
    
    const page = parseInt(button.dataset.page)
    this.loadProducts(page)
  }

  // Show error message
  showError(message) {
    if (!this.hasProductsListTarget) return
    
    this.productsListTarget.innerHTML = `
      <div class="text-center py-8 text-error">
        <i class="fas fa-exclamation-triangle text-3xl mb-4"></i>
        <p>${message}</p>
      </div>
    `
  }
} 