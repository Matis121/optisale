# Optisale 📊

A modern, multi-tenant order and inventory management system built with Ruby on Rails 8. Optisale helps businesses streamline their sales operations, manage inventory across multiple warehouses, and automate invoice generation.

![Ruby](https://img.shields.io/badge/Ruby-3.3.5-red)
![Rails](https://img.shields.io/badge/Rails-8.0.2-red)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-blue)
![Tailwind CSS](https://img.shields.io/badge/Tailwind%20CSS-38B2AC)
![DaisyUI](https://img.shields.io/badge/DaisyUI-5.0.35-5A0EF8)

## ✨ Features

### 📦 Order Management
- **Complete Order Lifecycle**: Manage orders from creation to fulfillment
- **Custom Order Statuses**: Define and organize custom order statuses with groups
- **Bulk Operations**: Update multiple orders simultaneously
- **Customer Information**: Track customer details, addresses, and pickup points
- **Payment Tracking**: Monitor payment status and amounts
- **Flexible Fields**: Extra custom fields for business-specific data

### 📊 Inventory Management
- **Multi-Warehouse Support**: Manage stock across multiple warehouses
- **Stock Movement Tracking**: Complete audit trail of all stock changes
- **Real-time Stock Levels**: Track inventory in real-time
- **Product Catalogs**: Organize products into different catalogs
- **Price Groups**: Define multiple pricing tiers for different customer segments
- **SKU & EAN Support**: Track products with multiple identifiers

### 💰 Invoicing
- **Automated Invoice Generation**: Create invoices directly from orders
- **External Integration**: Connect with Fakturownia (Polish invoicing system)
- **Invoice Management**: View, sync, and manage invoice status
- **Multi-Currency Support**: Handle different currencies

### 🔗 Integrations
- **Fakturownia Integration**: Automatic invoice generation and sync
- **Extensible Architecture**: Ready for marketplace and shipping integrations
- **API-First Design**: Built with future integrations in mind

### 👥 Multi-Tenancy & User Management
- **Account Isolation**: Complete data separation between accounts
- **Role-Based Access**: Owner and user roles
- **User Management**: Add and manage team members
- **NIP Validation**: Polish tax identification number validation

### 📈 Analytics & Reporting
- **Dashboard**: Overview of key metrics and recent activities
- **Sales Statistics**: Track sales trends over time
- **Stock Reports**: Monitor inventory levels and movements
- **Custom Queries**: Advanced filtering and search capabilities

## 🛠️ Technology Stack

- **Backend**: Ruby on Rails 8.0.2
- **Database**: PostgreSQL
- **Frontend**: 
  - Hotwire (Turbo & Stimulus)
  - Tailwind CSS with DaisyUI components
  - View Components for reusable UI elements
- **Authentication**: Devise
- **Search & Filtering**: Ransack
- **Pagination**: Kaminari
- **Background Jobs**: Sidekiq
- **Icons**: Lucide Rails & Font Awesome

## 🚀 Getting Started

### Prerequisites

- Ruby 3.3.5
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- Redis (optional, for Action Cable in production)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/optisale.git
   cd optisale
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Setup database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Start the development server**
   ```bash
   bin/dev
   ```

5. **Visit the application**
   Open your browser and navigate to `http://localhost:3000`


## 📋 Configuration

### Invoicing Integration (Fakturownia)

1. Go to **Integrations**
2. Click **Add** on Fakturownia
3. Enter your API credentials:
   - Account name (subdomain)
   - API token

## 🏗️ Architecture

### Database Schema Highlights

- **Multi-tenant architecture**: All data scoped to accounts
- **Polymorphic associations**: Flexible integration system
- **Audit trails**: Complete history of stock movements
- **Optimized indexes**: Fast queries for large datasets

### Key Models

- `Account` - Multi-tenant organization
- `Order` - Core order management
- `Product` - Product catalog with pricing
- `Warehouse` - Inventory locations
- `StockMovement` - Audit trail for inventory
- `Invoice` - Invoice records and external sync
- `InvoicingIntegration` - External service connections

## 🧪 Testing

The project uses RSpec for testing:

```bash
# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/models/order_spec.rb
```

## 🗺️ Roadmap

[ ] Marketplace integrations (Allegro, Amazon, eBay)
[ ] Shipping integrations (DPD, InPost, DHL)
[ ] Advanced reporting and analytics
[ ] Mobile responsive design
[ ] Dark mode / Light mode system
[ ] REST API for external integrations
[ ] Automated order workflows
[ ] Email notifications
[ ] Multi-language support
[ ] Advanced permissions system
[ ] Advanced Analytics and Reporting

---

Made with ❤️ for Simple E-commerce
