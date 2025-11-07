class IntegrationsController < ApplicationController
  before_action :set_integration, only: [ :show, :edit, :update, :destroy, :test ]

  def index
    @invoicing_integrations = current_account.invoicing_integrations.order(:created_at)
    @available_invoicing_providers = available_invoicing_providers.map do |provider|
      has_provider = @invoicing_integrations.any? { |i| i.provider == provider[:key] }
      can_add = provider[:multiple_allowed] || !has_provider

      provider.merge(has_provider: has_provider, can_add: can_add)
    end
  end

  def show
    @test_result = session.delete(:test_result)
  end

  def new
    @integration = current_account.invoicing_integrations.build
    @provider = params[:provider]

    unless valid_provider?(@provider)
      redirect_to integrations_path, alert: "Nieprawidłowy provider"
      return
    end

    @integration.provider = @provider
    @integration.credentials = {} if @integration.credentials.blank?
    @required_fields = InvoicingIntegration.required_credentials_for(@provider)
  end

  def create
    @integration = current_account.invoicing_integrations.build(integration_params)
    @provider = @integration.provider
    @required_fields = InvoicingIntegration.required_credentials_for(@integration.provider)

    if @integration.save
      redirect_to integration_path(@integration), notice: "Integracja została utworzona. Przetestuj połączenie aby ją aktywować."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Ensure credentials is properly initialized
    begin
      creds = @integration.credentials
      @integration.credentials = {} if creds.blank? || !creds.is_a?(Hash)
    rescue
      @integration.credentials = {}
    end
    @required_fields = InvoicingIntegration.required_credentials_for(@integration.provider)
  end

  def update
    @required_fields = InvoicingIntegration.required_credentials_for(@integration.provider)

    if should_merge_credentials?
      merge_credentials
      update_params = integration_params.except(:credentials)
    else
      update_params = integration_params
    end

    if @integration.update(update_params)
      redirect_to integration_path(@integration), notice: "Integracja została zaktualizowana."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @integration.destroy
    redirect_to integrations_path, notice: "Integracja została usunięta."
  end

  def test
    begin
      if @integration.test_connection
        redirect_to integration_path(@integration), notice: "Połączenie z #{@integration.provider.humanize} zostało pomyślnie przetestowane i integracja została aktywowana!"
      else
        redirect_to integration_path(@integration), alert: "Test połączenia nie powiódł się: #{@integration.error_message || 'Sprawdź dane logowania.'}"
      end
    rescue => e
      Rails.logger.error "Test connection failed: #{e.message}"
      redirect_to integration_path(@integration), alert: "Test połączenia nie powiódł się: #{e.message}"
    end
  end

  private

  def should_merge_credentials?
    params.dig(:invoicing_integration, :credentials).present?
  end

  def merge_credentials
    new_creds = integration_params[:credentials]
    existing_creds = (@integration.credentials || {}).stringify_keys

    # Only update non-blank values
    new_creds.each do |key, value|
      existing_creds[key.to_s] = value if value.present?
    end

    @integration.credentials = existing_creds
  end

  def set_integration
    @integration = current_account.invoicing_integrations.find(params[:id])
  end

  def integration_params
    permitted = params.require(:invoicing_integration).permit(
      :provider, :name, :active,
      credentials: [ :account, :api_token ]
    )

    # Convert ActionController::Parameters to Hash for credentials
    if permitted[:credentials].present?
      permitted[:credentials] = permitted[:credentials].to_h
    end
    permitted
  end

  def available_invoicing_providers
    [
      {
        key: "fakturownia",
        name: "Fakturownia",
        description: "Popularna platforma do wystawiania faktur",
        logo_class: "fas fa-file-invoice",
        logo_image: "fakturownia.png",
        required_fields: InvoicingIntegration.required_credentials_for("fakturownia"),
        multiple_allowed: false
      }
    ]
  end


  def valid_provider?(provider)
    available_invoicing_providers.any? { |p| p[:key] == provider }
  end
end
