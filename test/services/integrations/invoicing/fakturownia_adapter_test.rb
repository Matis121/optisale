require "test_helper"
require "webmock/minitest"

class Integrations::Invoicing::FakturowniaAdapterTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Test Fakturownia",
      credentials: {
        api_token: "test_token_123",
        account: "testaccount"
      }
    )
    @adapter = @integration.adapter
    @base_url = "https://testaccount.fakturownia.pl"

    # Tworzenie testowego zamówienia z adresami
    @customer = customers(:one)
    @order = Order.create!(
      user: @user,
      customer: @customer,
      status_id: order_statuses(:one).id,
      shipping_cost: 15.00
    )

    # Clear default addresses created by after_initialize
    @order.addresses.destroy_all

    # Adresy fakturowania i dostawy
    @invoice_address = Address.create!(
      order: @order,
      kind: "invoice",
      fullname: "Jan Kowalski",
      company_name: "Test Company",
      street: "Testowa 123",
      city: "Warszawa",
      postcode: "00-001",
      country: "PL"
    )

    @delivery_address = Address.create!(
      order: @order,
      kind: "delivery",
      fullname: "Jan Kowalski",
      street: "Dostawcza 456",
      city: "Kraków",
      postcode: "30-001",
      country: "PL"
    )

    # Produkty w zamówieniu
    @product = products(:one)
    @order_product = OrderProduct.create!(
      order: @order,
      product: @product,
      name: "Test Product",
      sku: "TEST-001",
      ean: "1234567890123",
      quantity: 2,
      gross_price: 100.00,
      tax_rate: 23
    )

    # Reload order to ensure addresses are loaded from database
    @order.reload

    WebMock.disable_net_connect!(allow_localhost: true)
  end

  def teardown
    WebMock.reset!
  end

  # Test connection
  test "test_connection should return true on successful connection" do
    stub_request(:get, "#{@base_url}/invoices.json")
      .with(query: { api_token: "test_token_123", per_page: 1 })
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    assert @adapter.test_connection
  end

  test "test_connection should raise error on failed connection" do
    stub_request(:get, "#{@base_url}/invoices.json")
      .with(query: { api_token: "test_token_123", per_page: 1 })
      .to_return(status: 401, body: { error: "Unauthorized" }.to_json)

    assert_raises(RuntimeError) do
      @adapter.test_connection
    end
  end

  # Create invoice
  test "create_invoice should create invoice and return local invoice record" do
    fakturownia_response = {
      id: 12345,
      number: "INV/2025/001",
      price_gross: 215.00,
      issue_date: Date.current.to_s,
      payment_to: 14.days.from_now.to_s,
      status: "issued"
    }

    stub_request(:post, "#{@base_url}/invoices.json")
      .with(
        body: hash_including({
          api_token: "test_token_123",
          invoice: hash_including({
            kind: "vat",
            buyer_name: "Test Company"
          })
        })
      )
      .to_return(status: 201, body: fakturownia_response.to_json)

    assert_difference "Invoice.count", 1 do
      invoice = @adapter.create_invoice(@order)

      assert_not_nil invoice
      assert_equal "INV/2025/001", invoice.invoice_number
      assert_equal "12345", invoice.external_id
      assert_equal 215.00, invoice.amount
      assert_equal "sent", invoice.status
    end
  end

  test "create_invoice should raise error on failed request" do
    stub_request(:post, "#{@base_url}/invoices.json")
      .to_return(status: 422, body: { error: "Invalid data" }.to_json)

    assert_raises(RuntimeError) do
      @adapter.create_invoice(@order)
    end
  end

  test "create_invoice should build correct invoice payload" do
    stub_request(:post, "#{@base_url}/invoices.json")
      .to_return(status: 201, body: {
        id: 12345,
        number: "INV/001",
        price_gross: 215.00,
        issue_date: Date.current.to_s,
        payment_to: 14.days.from_now.to_s,
        status: "issued"
      }.to_json)

    @adapter.create_invoice(@order)

    assert_requested(:post, "#{@base_url}/invoices.json") do |req|
      body = JSON.parse(req.body)
      invoice_data = body["invoice"]

      # Sprawdzamy dane klienta (company_name ma precedencję nad fullname)
      assert_equal "Test Company", invoice_data["buyer_name"]
      assert_equal "Testowa 123", invoice_data["buyer_street"]
      assert_equal "Warszawa", invoice_data["buyer_city"]
      assert_equal "00-001", invoice_data["buyer_post_code"]

      # Sprawdzamy pozycje
      assert_equal 1, invoice_data["positions"].length
      position = invoice_data["positions"].first
      assert_equal "Test Product 1", position["name"]  # Name from fixtures
      assert_equal 2, position["quantity"]
      assert_equal "23.0", position["tax"]  # Tax rate as string

      # Sprawdzamy metadane
      assert_equal "vat", invoice_data["kind"]
      assert_equal "pl", invoice_data["lang"]
      assert_equal "PLN", invoice_data["currency"]

      true
    end
  end

  # Delete invoice
  test "delete_invoice should return true on successful deletion" do
    invoice = Invoice.create!(
      user: @user,
      order: @order,
      invoicing_integration: @integration,
      invoice_number: "INV/001",
      external_id: "12345",
      amount: 100.00,
      issue_date: Date.current,
      due_date: 14.days.from_now,
      status: "sent"
    )

    stub_request(:delete, "#{@base_url}/invoices/12345.json")
      .with(query: { api_token: "test_token_123" })
      .to_return(status: 200, body: "ok")

    assert @adapter.delete_invoice(invoice)
  end

  test "delete_invoice should return true when invoice not found (404)" do
    invoice = Invoice.create!(
      user: @user,
      order: @order,
      invoicing_integration: @integration,
      invoice_number: "INV/001",
      external_id: "12345",
      amount: 100.00,
      issue_date: Date.current,
      due_date: 14.days.from_now,
      status: "sent"
    )

    stub_request(:delete, "#{@base_url}/invoices/12345.json")
      .with(query: { api_token: "test_token_123" })
      .to_return(status: 404)

    assert @adapter.delete_invoice(invoice)
  end

  test "delete_invoice should return false on error" do
    invoice = Invoice.create!(
      user: @user,
      order: @order,
      invoicing_integration: @integration,
      invoice_number: "INV/001",
      external_id: "12345",
      amount: 100.00,
      issue_date: Date.current,
      due_date: 14.days.from_now,
      status: "sent"
    )

    stub_request(:delete, "#{@base_url}/invoices/12345.json")
      .with(query: { api_token: "test_token_123" })
      .to_return(status: 500, body: { error: "Server error" }.to_json)

    assert_not @adapter.delete_invoice(invoice)
  end

  # URL methods
  test "view_url should return correct URL" do
    invoice = Invoice.create!(
      user: @user,
      order: @order,
      invoicing_integration: @integration,
      invoice_number: "INV/001",
      external_id: "12345",
      amount: 100.00,
      issue_date: Date.current,
      due_date: 14.days.from_now,
      status: "sent"
    )

    expected_url = "#{@base_url}/invoices/12345"
    assert_equal expected_url, @adapter.view_url(invoice)
  end

  test "download_pdf_url should return correct URL with token" do
    invoice = Invoice.create!(
      user: @user,
      order: @order,
      invoicing_integration: @integration,
      invoice_number: "INV/001",
      external_id: "12345",
      amount: 100.00,
      issue_date: Date.current,
      due_date: 14.days.from_now,
      status: "sent"
    )

    expected_url = "#{@base_url}/invoices/12345.pdf?api_token=test_token_123"
    assert_equal expected_url, @adapter.download_pdf_url(invoice)
  end

  # Status mapping
  test "map_status_from_fakturownia should map all statuses correctly" do
    adapter = @integration.adapter

    assert_equal "sent", adapter.send(:map_status_from_fakturownia, "issued")
    assert_equal "sent", adapter.send(:map_status_from_fakturownia, "sent")
    assert_equal "paid", adapter.send(:map_status_from_fakturownia, "paid")
    assert_equal "cancelled", adapter.send(:map_status_from_fakturownia, "cancelled")
    assert_equal "partial", adapter.send(:map_status_from_fakturownia, "partial")
    assert_equal "draft", adapter.send(:map_status_from_fakturownia, "unknown")
    assert_equal "draft", adapter.send(:map_status_from_fakturownia, nil)
  end

  # Credential validation
  test "validate_credentials! should raise error when api_token is missing" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Invalid Integration",
      credentials: { account: "testaccount" }
    )
    adapter = integration.adapter

    assert_raises(RuntimeError, "API token is required") do
      adapter.send(:validate_credentials!)
    end
  end

  test "validate_credentials! should raise error when account is missing" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Invalid Integration",
      credentials: { api_token: "test_token" }
    )
    adapter = integration.adapter

    assert_raises(RuntimeError, "Account subdomain is required") do
      adapter.send(:validate_credentials!)
    end
  end

  test "validate_credentials! should raise error on invalid account format" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Invalid Integration",
      credentials: {
        api_token: "test_token",
        account: "invalid account!"
      }
    )
    adapter = integration.adapter

    assert_raises(RuntimeError, "Invalid account format") do
      adapter.send(:validate_credentials!)
    end
  end

  # Helper methods
  test "calculate_net_price should calculate correctly" do
    adapter = @integration.adapter

    # With 23% VAT
    net_price = adapter.send(:calculate_net_price, 123.00, 23)
    assert_equal 100.00, net_price

    # With 0% VAT
    net_price = adapter.send(:calculate_net_price, 100.00, 0)
    assert_equal 100.00, net_price

    # With 8% VAT
    net_price = adapter.send(:calculate_net_price, 108.00, 8)
    assert_equal 100.00, net_price
  end

  test "build_delivery_address should format address correctly" do
    adapter = @integration.adapter

    shipping_data = {
      name: "Jan Kowalski",
      street: "Testowa 123",
      postal_code: "00-001",
      city: "Warszawa"
    }

    address = adapter.send(:build_delivery_address, shipping_data)
    assert_includes address, "Jan Kowalski"
    assert_includes address, "Testowa 123"
    assert_includes address, "00-001 Warszawa"
  end

  test "build_delivery_address should return nil for empty address" do
    adapter = @integration.adapter

    assert_nil adapter.send(:build_delivery_address, nil)
    assert_nil adapter.send(:build_delivery_address, { street: "" })
    assert_nil adapter.send(:build_delivery_address, {})
  end
end
