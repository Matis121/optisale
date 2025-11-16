module Integrations
  module Invoicing
    class FakturowniaAdapter < BaseAdapter
      BASE_URL_TEMPLATE = "https://%{account}.fakturownia.pl"

      def test_connection
        response = http_client.get("#{base_url}/invoices.json", params: {
          api_token: api_token,
          per_page: 1
        })

        return true if response.status == 200

        handle_http_error(response, "testing connection")
      end

      def create_invoice(order)
        invoice_data = build_invoice_payload(order)

        response = http_client.post("#{base_url}/invoices.json", json: {
          api_token: api_token,
          invoice: invoice_data
        })

        if response.status == 201
          data = JSON.parse(response.body)
          create_local_invoice(order, data)
        else
          handle_http_error(response, "creating invoice")
        end
      end

      def get_invoice_status(invoice)
        response = http_client.get("#{base_url}/invoices/#{invoice.external_id}.json",
                                  params: { api_token: api_token })

        if response.status == 200
          data = JSON.parse(response.body)
          map_status_from_fakturownia(data["status"])
        else
          handle_http_error(response, "getting invoice status")
        end
      rescue => e
        log_error("Failed to get status for invoice #{invoice.id}", e)
        "error"
      end

      def view_url(invoice)
        "#{base_url}/invoices/#{invoice.external_id}"
      end

      def download_pdf_url(invoice)
        "#{base_url}/invoices/#{invoice.external_id}.pdf?api_token=#{api_token}"
      end

      def cancel_invoice(invoice)
        response = http_client.put("#{base_url}/invoices/#{invoice.external_id}.json", json: {
          api_token: api_token,
          invoice: { status: "cancelled" }
        })

        if response.status == 200
          true
        else
          handle_http_error(response, "cancelling invoice")
        end
      rescue => e
        log_error("Failed to cancel invoice #{invoice.id}", e)
        false
      end

      def delete_invoice(invoice)
        response = http_client.delete("#{base_url}/invoices/#{invoice.external_id}.json", params: {
          api_token: api_token
        })

        if response.status == 200 && (response.body.to_s.strip == "ok" || response.body.to_s.include?("ok"))
          # Invoice was successfully deleted from Fakturownia
          true
        elsif response.status == 404
          # Invoice no longer exists in Fakturownia - treat as success
          # (probably already deleted manually)
          true
        else
          handle_http_error(response, "deleting invoice")
          false
        end
      rescue => e
        log_error("Failed to delete invoice #{invoice.id}", e)
        false
      end

      private

      def base_url
        if account.blank?
          raise "Account name is missing from credentials"
        end
        @base_url ||= BASE_URL_TEMPLATE % { account: account }
      end

      def api_token
        @api_token ||= credentials[:api_token] || credentials["api_token"]
      end

      def account
        @account ||= credentials[:account] || credentials["account"]
      end

      def build_invoice_payload(order)
        data = order_to_invoice_data(order)

        {
          kind: "vat",
          number: nil, # Auto-generate
          sell_date: Date.current.strftime("%Y-%m-%d"),
          issue_date: Date.current.strftime("%Y-%m-%d"),
          payment_to: 14.days.from_now.strftime("%Y-%m-%d"),
          payment_type: "transfer",

          # Customer data
          buyer_name: data[:customer][:company] || data[:customer][:name],
          buyer_tax_no: data[:customer][:tax_id],
          buyer_email: data[:customer][:email],
          buyer_phone: data[:customer][:phone],

          # Billing address
          buyer_street: data[:addresses][:billing][:street],
          buyer_city: data[:addresses][:billing][:city],
          buyer_post_code: data[:addresses][:billing][:postal_code],
          buyer_country: data[:addresses][:billing][:country] || "PL",

          # Shipping address (if different)
          delivery_address: build_delivery_address(data[:addresses][:shipping]),

          # Items
          positions: data[:items].map { |item| map_item_to_fakturownia(item) },

          # Additional options
          lang: "pl",
          currency: "PLN",
          exchange_currency: "PLN",

          # Internal reference
          description: "Zamówienie ##{data[:order_id]}"
        }
      end

      def build_delivery_address(shipping_address)
        return nil if shipping_address.blank? || shipping_address[:street].blank?

        "#{shipping_address[:name]}\n#{shipping_address[:street]}\n#{shipping_address[:postal_code]} #{shipping_address[:city]}"
      end

      def map_item_to_fakturownia(item)
        net_price = calculate_net_price(item[:unit_price], item[:tax_rate])

        {
          name: item[:name],
          tax: item[:tax_rate],
          price_net: net_price,
          quantity: item[:quantity],
          total_price_gross: item[:total],

          # Optional fields
          code: item[:sku],
          ean_code: item[:ean]
        }.compact
      end

      def calculate_net_price(gross_price, tax_rate)
        return gross_price if tax_rate.to_f.zero?

        (gross_price / (1 + tax_rate.to_f / 100.0)).round(2)
      end

      def create_local_invoice(order, fakturownia_data)
        invoice = Invoice.create!(
          account: order.account,
          order: order,
          invoicing_integration: integration,
          invoice_number: fakturownia_data["number"],
          external_id: fakturownia_data["id"].to_s,
          amount: fakturownia_data["price_gross"].to_f,
          issue_date: Date.parse(fakturownia_data["issue_date"]),
          due_date: Date.parse(fakturownia_data["payment_to"]),
          external_url: view_url_for_id(fakturownia_data["id"]),
          external_data: fakturownia_data,
          status: map_status_from_fakturownia(fakturownia_data["status"])
        )

        invoice
      rescue ActiveRecord::RecordInvalid => e
        log_error("Failed to create local invoice record", e)
        raise "Failed to save invoice: #{e.message}"
      end

      def map_status_from_fakturownia(fakturownia_status)
        case fakturownia_status&.downcase
        when "issued", "sent"
          "sent"
        when "paid"
          "paid"
        when "cancelled"
          "cancelled"
        when "partial"
          "partial"
        else
          "draft"
        end
      end

      def view_url_for_id(external_id)
        "#{base_url}/invoices/#{external_id}"
      end

      def handle_http_error(response, action)
        error_message = "HTTP #{response.status} error while #{action}"

        begin
          error_data = JSON.parse(response.body)
          error_message += ": #{error_data['message'] || error_data['error']}" if error_data["message"] || error_data["error"]
        rescue JSON::ParserError
          error_message += ": #{response.body.to_s.truncate(200)}"
        end

        log_error(error_message)
        raise error_message
      end

      # Credentials validation
      def validate_credentials!
        raise "API token is required" if api_token.blank?
        raise "Account subdomain is required" if account.blank?

        # Basic format validation
        raise "Invalid account format" unless account.match?(/\A[a-zA-Z0-9\-_]+\z/)
      end
    end
  end
end
