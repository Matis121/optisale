module Integrations
  module Invoicing
    class BaseAdapter < Integrations::BaseAdapter
      # Interface to implement in specific invoicing adapters

      # Creates invoice in external system
      def create_invoice(order)
        raise NotImplementedError, "Subclass must implement create_invoice"
      end

      # Gets invoice status from external system
      def get_invoice_status(invoice)
        raise NotImplementedError, "Subclass must implement get_invoice_status"
      end

      # Returns URL to invoice preview
      def view_url(invoice)
        raise NotImplementedError, "Subclass must implement view_url"
      end

      # Zwraca URL do pobrania PDF faktury
      def download_pdf_url(invoice)
        raise NotImplementedError, "Subclass must implement download_pdf_url"
      end

      # Cancels invoice
      def cancel_invoice(invoice)
        raise NotImplementedError, "Subclass must implement cancel_invoice"
      end

      # Deletes invoice from external system
      def delete_invoice(invoice)
        raise NotImplementedError, "Subclass must implement delete_invoice"
      end

      protected

      # Converts order to standard invoice format
      def order_to_invoice_data(order)
        {
          order_id: order.id,
          customer: customer_data(order),
          items: order_items_data(order),
          amounts: amounts_data(order),
          addresses: addresses_data(order)
        }
      end

      private

      def customer_data(order)
        customer = order.customer
        invoice_address = order.addresses.invoice.first

        # Use user email as fallback if customer email is invalid
        email = customer&.email
        if email.blank? || !email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
          email = order.user.email
        end

        {
          name: invoice_address&.fullname || customer&.login || "Unknown Customer",
          email: email,
          company: invoice_address&.company_name,
          tax_id: nil, # Customer model doesn't have tax_id
          phone: customer&.phone # Phone is in customer, not address
        }
      end

      def order_items_data(order)
        order.order_products.map do |item|
          {
            name: item.name || "Unknown Product",
            sku: item.sku,
            ean: item.ean,
            quantity: item.quantity,
            unit_price: item.gross_price,
            tax_rate: item.tax_rate || 23, # Default VAT rate for Poland
            total: item.quantity * item.gross_price
          }
        end
      end

      def amounts_data(order)
        subtotal = order.order_products.sum { |item| item.quantity * item.gross_price }
        shipping = order.shipping_cost || 0

        {
          subtotal: subtotal,
          shipping: shipping,
          total: subtotal + shipping
        }
      end

      def addresses_data(order)
        {
          billing: address_data(order.addresses.invoice.first),
          shipping: address_data(order.addresses.delivery.first)
        }
      end

      def address_data(address)
        return {} unless address

        {
          name: address.fullname,
          company: address.company_name,
          street: address.street,
          city: address.city,
          postal_code: address.postcode,
          country: address.country || "PL",
          phone: nil # Address doesn't have phone - it's in customer
        }
      end
    end
  end
end
