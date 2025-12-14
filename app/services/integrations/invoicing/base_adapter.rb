module Integrations
  module Invoicing
    class BaseAdapter < Integrations::BaseAdapter
      def export_invoice(invoice)
        return unless settings["auto_export_invoices"]
        do_export_invoice(invoice)
      end

      def export_receipt(receipt)
        return unless settings["auto_export_receipts"]
        do_export_receipt(receipt)
      end

      def payment_methods
        []
      end

      def download_pdf(invoice)
        raise NotImplementedError
      end

      def delete_invoice(invoice)
        raise NotImplementedError
      end
    end
  end
end
