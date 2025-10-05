require "test_helper"
require "webmock/minitest"

class FakturowniaIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    sign_in @user

    @integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Test Fakturownia",
      credentials: {
        api_token: "test_token_123",
        account: "testaccount"
      },
      status: "active",
      active: true
    )

    @base_url = "https://testaccount.fakturownia.pl"

    # Tworzenie kompletnego zamówienia
    @customer = customers(:one)
    @order = Order.create!(
      user: @user,
      customer: @customer,
      status_id: order_statuses(:one).id,
      shipping_cost: 15.00
    )

    # Clear default addresses created by after_initialize
    @order.addresses.destroy_all

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

    @product = products(:one)
    @order_product = OrderProduct.create!(
      order: @order,
      product: @product,
      name: "Test Product",
      sku: "TEST-001",
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

  # Test pełnego procesu: dodanie integracji -> test połączenia -> utworzenie faktury
  test "complete workflow: add integration, test connection, create invoice" do
    # 1. Test połączenia
    stub_request(:get, "#{@base_url}/invoices.json")
      .with(query: { api_token: "test_token_123", per_page: 1 })
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    assert @integration.test_connection
    @integration.reload
    assert_equal "active", @integration.status
    assert @integration.active

    # 2. Utworzenie faktury
    fakturownia_response = {
      id: 12345,
      number: "INV/2025/001",
      price_gross: 215.00,
      issue_date: Date.current.to_s,
      payment_to: 14.days.from_now.to_s,
      status: "issued"
    }

    stub_request(:post, "#{@base_url}/invoices.json")
      .to_return(status: 201, body: fakturownia_response.to_json)

    assert_difference "Invoice.count", 1 do
      invoice = @integration.adapter.create_invoice(@order)

      assert_not_nil invoice
      assert_equal "INV/2025/001", invoice.invoice_number
      assert_equal @order, invoice.order
      assert_equal @user, invoice.user
      assert_equal @integration, invoice.invoicing_integration
    end
  end

  # Test usuwania faktury
  test "should delete invoice from fakturownia" do
    # Utworzenie faktury
    fakturownia_response = {
      id: 12345,
      number: "INV/2025/001",
      price_gross: 215.00,
      issue_date: Date.current.to_s,
      payment_to: 14.days.from_now.to_s,
      status: "issued"
    }

    stub_request(:post, "#{@base_url}/invoices.json")
      .to_return(status: 201, body: fakturownia_response.to_json)

    invoice = @integration.adapter.create_invoice(@order)

    # Usunięcie faktury z Fakturowni
    stub_request(:delete, "#{@base_url}/invoices/12345.json")
      .with(query: { api_token: "test_token_123" })
      .to_return(status: 200, body: "ok")

    assert @integration.adapter.delete_invoice(invoice)

    # Lokalnie faktura nadal istnieje (tylko usunięta z systemu zewnętrznego)
    assert Invoice.exists?(invoice.id)
  end

  # Test obsługi błędów podczas tworzenia faktury
  test "should handle errors when creating invoice" do
    stub_request(:post, "#{@base_url}/invoices.json")
      .to_return(status: 422, body: {
        error: "Invalid invoice data",
        message: "Buyer name is required"
      }.to_json)

    assert_raises(RuntimeError) do
      @integration.adapter.create_invoice(@order)
    end

    # Faktura nie została utworzona lokalnie
    assert_equal 0, Invoice.where(order: @order).count
  end

  # Test obsługi błędów połączenia
  test "should handle connection errors" do
    stub_request(:get, "#{@base_url}/invoices.json")
      .with(query: { api_token: "test_token_123", per_page: 1 })
      .to_return(status: 401, body: { error: "Unauthorized" }.to_json)

    assert_not @integration.test_connection
    @integration.reload
    assert_equal "error", @integration.status
    assert_not @integration.active
    assert_not_nil @integration.error_message
  end

  # Test nieprawidłowych danych uwierzytelniających
  test "should fail with invalid credentials" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Invalid Fakturownia",
      credentials: {
        api_token: "wrong_token",
        account: "wrongaccount"
      }
    )

    stub_request(:get, "https://wrongaccount.fakturownia.pl/invoices.json")
      .with(query: { api_token: "wrong_token", per_page: 1 })
      .to_return(status: 403, body: { error: "Forbidden" }.to_json)

    assert_not integration.test_connection
    integration.reload
    assert_equal "error", integration.status
  end

  # Test wielokrotnego tworzenia faktur dla tego samego zamówienia
  test "should prevent creating duplicate invoices for same order" do
    fakturownia_response = {
      id: 12345,
      number: "INV/2025/001",
      price_gross: 215.00,
      issue_date: Date.current.to_s,
      payment_to: 14.days.from_now.to_s,
      status: "issued"
    }

    stub_request(:post, "#{@base_url}/invoices.json")
      .to_return(status: 201, body: fakturownia_response.to_json)

    # Pierwsza faktura - powinna się utworzyć
    invoice1 = @integration.adapter.create_invoice(@order)
    assert_not_nil invoice1

    # Druga faktura dla tego samego zamówienia - powinna zgłosić błąd walidacji
    fakturownia_response[:id] = 67890
    fakturownia_response[:number] = "INV/2025/002"

    stub_request(:post, "#{@base_url}/invoices.json")
      .to_return(status: 201, body: fakturownia_response.to_json)

    assert_raises(RuntimeError, /Failed to save invoice/) do
      @integration.adapter.create_invoice(@order)
    end
  end

  # Test automatycznej aktywacji po udanym teście połączenia
  test "should automatically activate integration after successful connection test" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "New Fakturownia",
      credentials: {
        api_token: "new_token",
        account: "newaccount"
      },
      status: "inactive",
      active: false
    )

    stub_request(:get, "https://newaccount.fakturownia.pl/invoices.json")
      .with(query: { api_token: "new_token", per_page: 1 })
      .to_return(status: 200, body: "[]")

    assert integration.test_connection
    integration.reload

    assert_equal "active", integration.status
    assert integration.active
    assert_nil integration.error_message
    assert_not_nil integration.last_sync_at
  end

  # Test URL-i faktury
  test "should generate correct invoice URLs" do
    fakturownia_response = {
      id: 12345,
      number: "INV/2025/001",
      price_gross: 215.00,
      issue_date: Date.current.to_s,
      payment_to: 14.days.from_now.to_s,
      status: "issued"
    }

    stub_request(:post, "#{@base_url}/invoices.json")
      .to_return(status: 201, body: fakturownia_response.to_json)

    invoice = @integration.adapter.create_invoice(@order)

    # URL do podglądu
    assert_equal "#{@base_url}/invoices/12345", invoice.view_url

    # URL do PDF
    assert_equal "#{@base_url}/invoices/12345.pdf?api_token=test_token_123", invoice.download_pdf_url
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
