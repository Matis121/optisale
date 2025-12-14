module Integrations
  module Invoicing
    class FakturowniaAdapter < BaseAdapter
      BASE_URL_TEMPLATE = "https://%{subdomain}.fakturownia.pl"

      def test_connection
        validate_credentials!

        response = http_client.get("#{base_url}/invoices.json", params: {
          api_token: api_token,
          per_page: 1
        })

        if response.status == 200
          true
        else
          raise "Sprawdź dane logowania (HTTP #{response.status})"
        end
      end

      # ========== FAKTURY ==========

      def do_export_invoice(invoice)
        validate_credentials!
        raise "Faktura nie ma pozycji" if invoice.invoice_items.empty?
        raise "Faktura już została wyeksportowana" if invoice.external_id.present?

        payload = build_invoice_payload(invoice)
        response = http_client.post("#{base_url}/invoices.json", json: {
          api_token: api_token,
          invoice: payload
        })

        if response.status == 201
          data = JSON.parse(response.body)
          invoice.update_columns(
            external_id: data["id"].to_s,
            external_invoice_number: data["number"]
          )
        else
          raise "Nie udało się wyeksportować faktury (HTTP #{response.body}, #{payload.inspect})"
        end
      end

      def download_invoice_pdf(invoice)
        download_pdf(invoice.external_id)
      end

      def delete_invoice(invoice)
        return if invoice.external_id.blank?

        delete_document(invoice.external_id)
        invoice.update_columns(external_id: nil, external_invoice_number: nil)
      end

      # ========== PARAGONY ==========

      def do_export_receipt(receipt)
        validate_credentials!
        raise "Paragon nie ma pozycji" if receipt.receipt_items.empty?
        raise "Paragon już został wyeksportowany" if receipt.external_id.present?

        payload = build_receipt_payload(receipt)
        response = http_client.post("#{base_url}/invoices.json", json: {
          api_token: api_token,
          invoice: payload
        })

        if response.status == 201
          data = JSON.parse(response.body)
          receipt.update_columns(
            external_id: data["id"].to_s,
            external_receipt_number: data["number"]
          )
        else
          raise "Nie udało się wyeksportować paragonu (HTTP #{response.status})"
        end
      end

      def download_receipt_pdf(receipt)
        download_pdf(receipt.external_id)
      end

      def delete_receipt(receipt)
        return if receipt.external_id.blank?

        delete_document(receipt.external_id)
        receipt.update_columns(external_id: nil, external_receipt_number: nil)
      end

      private

      # ========== WSPÓLNE ==========

      def download_pdf(external_id)
        return nil if external_id.blank?

        response = http_client.get("#{base_url}/invoices/#{external_id}.pdf", params: { api_token: api_token })

        if response.status == 200
          response.body.to_s
        else
          raise "Nie udało się pobrać PDF (HTTP #{response.status})"
        end
      end

      def delete_document(external_id)
        response = http_client.delete("#{base_url}/invoices/#{external_id}.json", params: {
          api_token: api_token
        })

        unless response.status == 200
          raise "Nie udało się usunąć dokumentu z Fakturowni (HTTP #{response.status})"
        end
      end

      def base_url
        raise "Subdomain is missing from credentials" if subdomain.blank?
        @base_url ||= BASE_URL_TEMPLATE % { subdomain: subdomain }
      end

      def api_token
        @api_token ||= credentials["api_token"]
      end

      def subdomain
        @subdomain ||= credentials["subdomain"]
      end

      def validate_credentials!
        raise "API token is required" if api_token.blank?
        raise "Subdomain is required" if subdomain.blank?
        raise "Invalid subdomain format" unless subdomain.match?(/\A[a-zA-Z0-9\-_]+\z/)
      end

      # ========== PAYLOADY ==========

      def build_invoice_payload(invoice)
        {
          kind: "vat",
          number: nil,
          sell_date: invoice.date_sell.strftime("%Y-%m-%d"),
          issue_date: invoice.date_add.strftime("%Y-%m-%d"),
          payment_to: invoice.date_pay_to&.strftime("%Y-%m-%d") || 14.days.from_now.strftime("%Y-%m-%d"),
          payment_type: map_payment_method(invoice.payment_method),
          buyer_name: invoice.invoice_company.presence || invoice.invoice_fullname,
          buyer_tax_no: invoice.invoice_nip,
          buyer_street: invoice.invoice_street,
          buyer_city: invoice.invoice_city,
          buyer_post_code: invoice.invoice_postcode,
          buyer_country: invoice.invoice_country || "PL",
          positions: invoice.invoice_items.map { |item| build_invoice_position(item) },
          lang: "pl",
          currency: invoice.currency || "PLN",
          exchange_currency: invoice.currency || "PLN",
          description: "Zamówienie ##{invoice.order_id}",
          oid: invoice.invoice_number
        }.compact
      end

      def build_receipt_payload(receipt)
        {
          kind: "receipt",
          number: nil,
          issue_date: receipt.date_add.strftime("%Y-%m-%d"),
          payment_type: map_payment_method(receipt.payment_method),
          buyer_tax_no: receipt.nip.presence,
          positions: receipt.receipt_items.map { |item| build_receipt_position(item) },
          lang: "pl",
          currency: receipt.currency || "PLN",
          description: "Zamówienie ##{receipt.order_id}",
          oid: receipt.receipt_number
        }.compact
      end

      def build_invoice_position(item)
        {
          name: item.name,
          tax: item.tax_rate.to_f,
          price_net: item.price_netto.to_f,
          quantity: item.quantity,
          total_price_gross: (item.price_brutto * item.quantity).to_f,
          code: item.sku,
          ean_code: item.ean
        }.compact
      end

      def build_receipt_position(item)
        price_netto = item.price_brutto / (1 + item.tax_rate.to_f / 100.0)
        {
          name: item.name,
          tax: item.tax_rate.to_f,
          price_net: price_netto.round(2),
          quantity: item.quantity,
          total_price_gross: (item.price_brutto * item.quantity).to_f,
          code: item.sku,
          ean_code: item.ean
        }.compact
      end

      def map_payment_method(payment_method)
        # Check if there's a custom mapping in settings
        mapping = account_integration.settings&.dig("payment_method_mapping")
        if mapping.present? && mapping.is_a?(Hash)
          mapped_value = mapping[payment_method.to_s]
          return mapped_value if mapped_value.present?

          default_value = mapping["default"]
          default_value if default_value.present?
        end
      end

      # Hardcoded list of payment methods in Fakturownia
      def self.available_payment_methods
        [
          { value: "Przelew", label: "Przelew" },
          { value: "Gotówka", label: "Gotówka" },
          { value: "Za Pobraniem", label: "Za Pobraniem" },
          { value: "Karta", label: "Karta" },
          { value: "PayPal", label: "PayPal" },
          { value: "PayU", label: "PayU" },
          { value: "Przelewy24", label: "Przelewy24" }
        ]
      end

      def payment_methods
        self.class.available_payment_methods
      end
    end
  end
end
