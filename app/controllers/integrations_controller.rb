class IntegrationsController < ApplicationController
  before_action :set_integration, only: [ :show, :edit, :update, :destroy, :test ]

  def index
    @integrations = current_user.integrations.order(:created_at)
    @available_providers = available_providers
  end

  def show
    @test_result = session.delete(:test_result) # Flash-like behavior for test results
  end

  def new
    @integration = current_user.integrations.build
    @provider = params[:provider]

    unless valid_provider?(@provider)
      redirect_to integrations_path, alert: "Nieprawidłowy provider"
      return
    end

    @integration.provider = @provider
    @required_fields = Integration.required_credentials_for(@provider)
  end

  def create
    @integration = current_user.integrations.build(integration_params)
    @required_fields = Integration.required_credentials_for(@integration.provider)

    # Validate required credentials are present
    @integration.validate_required_credentials

    if @integration.errors.empty? && @integration.save
      redirect_to @integration, notice: "Integracja została utworzona. Przetestuj połączenie aby ją aktywować."
    else
      @provider = @integration.provider
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @required_fields = Integration.required_credentials_for(@integration.provider)
  end

  def update
    @required_fields = Integration.required_credentials_for(@integration.provider)

    # Merge new credentials with existing ones (don't overwrite if field is empty)
    if params[:integration][:credentials].present?
      existing_credentials = @integration.credentials
      new_credentials = integration_params[:credentials]

      # Don't overwrite with empty values
      new_credentials.each do |key, value|
        existing_credentials[key] = value if value.present?
      end

      @integration.credentials = existing_credentials
    end

    # Update other attributes
    update_params = integration_params.except(:credentials)
    update_params[:credentials] = @integration.credentials if params[:integration][:credentials].present?

    @integration.validate_required_credentials

    if @integration.errors.empty? && @integration.update(update_params)
      redirect_to @integration, notice: "Integracja została zaktualizowana."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @integration.destroy
    redirect_to integrations_path, notice: "Integracja została usunięta."
  end

  def test
    if @integration.test_connection
      redirect_to @integration, notice: "Połączenie z #{@integration.provider.humanize} zostało pomyślnie przetestowane i integracja została aktywowana!"
    else
      redirect_to @integration, alert: "Test połączenia nie powiódł się: #{@integration.error_message || 'Sprawdź dane logowania.'}"
    end
  end


  private

  def set_integration
    @integration = current_user.integrations.find(params[:id])
  end

  def integration_params
    params.require(:integration).permit(
      :provider, :name, :active,
      credentials: {}
    )
  end

  def available_providers
    [
      {
        key: "fakturownia",
        name: "Fakturownia",
        description: "Popularna platforma do wystawiania faktur",
        logo_class: "fas fa-file-invoice",
        required_fields: Integration.required_credentials_for("fakturownia")
      }
    ]
  end

  def valid_provider?(provider)
    available_providers.any? { |p| p[:key] == provider }
  end
end
