class IntegrationsController < ApplicationController
  before_action :set_integration, only: [ :show, :edit, :update, :destroy, :test ]

  def index
    @invoicing_integrations = current_user.invoicing_integrations.order(:created_at)
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
    @integration = current_user.invoicing_integrations.build
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
    @integration = current_user.invoicing_integrations.build(integration_params)

    @required_fields = InvoicingIntegration.required_credentials_for(@integration.provider)

    # Validate required credentials are present
    @integration.validate_required_credentials

    if @integration.errors.empty? && @integration.save
      redirect_to integration_path(@integration), notice: "Integracja została utworzona. Przetestuj połączenie aby ją aktywować."
    else
      @provider = @integration.provider
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

    # Merge new credentials with existing ones (don't overwrite if field is empty)
    begin
      if params[:invoicing_integration] && params[:invoicing_integration][:credentials].present?
        existing_credentials = @integration.credentials
        new_credentials = integration_params[:credentials]

        # Ensure both are hashes
        existing_credentials = {} unless existing_credentials.is_a?(Hash)
        new_credentials = {} unless new_credentials.is_a?(Hash)

        # Don't overwrite with empty values
        new_credentials.each do |key, value|
          existing_credentials[key] = value if value.present?
        end

        # Update credentials directly
        @integration.credentials = existing_credentials

        # Update other attributes without credentials
        update_params = integration_params.except(:credentials)
      else
        # No credentials to update, use all params
        update_params = integration_params
      end
    rescue
      update_params = integration_params.except(:credentials)
    end

    @integration.validate_required_credentials

    if @integration.errors.empty? && @integration.update(update_params)
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

  def set_integration
    @integration = current_user.invoicing_integrations.find(params[:id])
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
        required_fields: InvoicingIntegration.required_credentials_for("fakturownia"),
        multiple_allowed: false
      }
    ]
  end


  def valid_provider?(provider)
    available_invoicing_providers.any? { |p| p[:key] == provider }
  end
end
