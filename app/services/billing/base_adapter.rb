module Billing
  class BaseAdapter
    attr_reader :integration

    def initialize(integration)
      @integration = integration
    end

    # Interface to implement in specific adapters

    # Connection test - returns true/false
    def test_connection
      raise NotImplementedError, "Subclass must implement test_connection"
    end

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

    # Helper methods available for all adapters

    def credentials
      integration.credentials
    end

    def configuration
      integration.configuration
    end

    def http_client
      @http_client ||= HTTP.timeout(30)
    end

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

    # Logs errors with context
    def log_error(message, error = nil)
      error_msg = "#{self.class.name}: #{message}"
      error_msg += " - #{error.message}" if error
      error_msg += "\n#{error.backtrace.join("\n")}" if error&.backtrace
    end

    # HTTP error handling
    def handle_http_error(response, context = nil)
      context_msg = context ? " (#{context})" : ""

      case response.status
      when 401
        raise "Unauthorized access#{context_msg}. Check your credentials."
      when 403
        raise "Forbidden access#{context_msg}. Check your permissions."
      when 404
        raise "Resource not found#{context_msg}."
      when 422
        error_details = extract_error_details(response)
        raise "Validation error#{context_msg}: #{error_details}"
      when 429
        raise "Rate limit exceeded#{context_msg}. Try again later."
      when 500..599
        raise "Server error#{context_msg}. Try again later."
      else
        raise "Unexpected response#{context_msg}: #{response.status} - #{response.body}"
      end
    end

    # Extracts error details from response
    def extract_error_details(response)
      return response.body.to_s unless response.content_type&.include?("json")

      begin
        error_data = JSON.parse(response.body)

        # Different error formats depending on API
        if error_data.is_a?(Hash)
          error_data["error"] || error_data["message"] || error_data["errors"]&.join(", ") || response.body
        else
          response.body
        end
      rescue JSON::ParserError
        response.body.to_s
      end
    end

    private

    def customer_data(order)
      customer = order.customer
      invoice_address = order.addresses.invoice.first

      {
        name: invoice_address&.fullname || customer&.login || "Unknown Customer",
        email: customer&.email,
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
