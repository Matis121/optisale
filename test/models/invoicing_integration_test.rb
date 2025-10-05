require "test_helper"

class InvoicingIntegrationTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should create valid invoicing integration with required credentials" do
    integration = InvoicingIntegration.new(
      user: @user,
      provider: "fakturownia",
      name: "Test Fakturownia",
      credentials: {
        api_token: "test_token_123",
        account: "testaccount"
      }
    )

    assert integration.valid?
    assert integration.save
  end

  test "should require valid provider" do
    integration = InvoicingIntegration.new(
      user: @user,
      provider: "invalid_provider",
      name: "Test Integration"
    )

    assert_not integration.valid?
    assert_includes integration.errors[:provider], "is not included in the list"
  end

  test "should return required credentials for fakturownia" do
    required = InvoicingIntegration.required_credentials_for("fakturownia")

    assert_includes required, "api_token"
    assert_includes required, "account"
    assert_equal 2, required.length
  end

  test "should validate required credentials presence" do
    integration = InvoicingIntegration.new(
      user: @user,
      provider: "fakturownia",
      name: "Test Fakturownia",
      credentials: { account: "testaccount" } # Missing api_token
    )

    integration.validate_required_credentials
    assert integration.errors[:credentials].any?
    assert_match(/api_token/, integration.errors[:credentials].first)
  end

  test "should serialize and deserialize credentials correctly" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Test Fakturownia",
      credentials: {
        api_token: "test_token_123",
        account: "testaccount"
      }
    )

    integration.reload

    assert_equal "test_token_123", integration.credentials["api_token"]
    assert_equal "testaccount", integration.credentials["account"]
  end

  test "should return fakturownia adapter for fakturownia provider" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Test Fakturownia",
      credentials: {
        api_token: "test_token",
        account: "testaccount"
      }
    )

    assert_instance_of Integrations::Invoicing::FakturowniaAdapter, integration.adapter
  end

  test "should have invoices association" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Test Fakturownia",
      credentials: {
        api_token: "test_token",
        account: "testaccount"
      }
    )

    assert_respond_to integration, :invoices
  end

  test "should destroy associated invoices when destroyed" do
    integration = InvoicingIntegration.create!(
      user: @user,
      provider: "fakturownia",
      name: "Test Fakturownia",
      credentials: {
        api_token: "test_token",
        account: "testaccount"
      }
    )

    order = Order.create!(
      user: @user,
      customer: customers(:one),
      status_id: order_statuses(:one).id
    )

    invoice = Invoice.create!(
      user: @user,
      order: order,
      invoicing_integration: integration,
      invoice_number: "INV/001",
      external_id: "123",
      amount: 100.00,
      issue_date: Date.current,
      due_date: 14.days.from_now,
      status: "sent"
    )

    assert_difference "Invoice.count", -1 do
      integration.destroy
    end
  end
end

