class AccountIntegrationsController < ApplicationController
  before_action :set_account_integration, only: [ :show, :edit, :update, :destroy, :test ]
  before_action :load_config, only: [ :show, :edit, :update ]

  def index
  end

  def show
  end

  def new
    @config = load_config_for(params[:provider])
    unless @config
      redirect_to integrations_path, alert: "Nieprawidłowy provider"
      return
    end

    integration = Integration.find_by(key: @config[:key])
    unless integration
      redirect_to integrations_path, alert: "Integracja nie jest dostępna"
      return
    end

    @account_integration = current_account.account_integrations.build(
      integration: integration,
      name: @config[:name],
      status: :inactive
    )

    prepare_payment_methods_data
  end

  def create
    integration = Integration.find_by(id: account_integration_params[:integration_id])
    unless integration
      redirect_to integrations_path, alert: "Nieprawidłowa integracja"
      return
    end

    @config = load_config_for(integration.key)
    unless @config
      redirect_to integrations_path, alert: "Brak konfiguracji dla tej integracji"
      return
    end

    @account_integration = current_account.account_integrations.build(account_integration_params)
    @account_integration.integration = integration
    @account_integration.status = :inactive

    if @account_integration.save
      redirect_to edit_account_integration_path(@account_integration), notice: "Integracja została utworzona. Przetestuj połączenie aby ją aktywować."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_payment_methods_data
  end

  def update
    if should_merge_credentials?
      merge_credentials
      update_params = account_integration_params.except(:credentials)
    else
      update_params = account_integration_params
    end

    if @account_integration.update(update_params)
      redirect_to edit_account_integration_path(@account_integration), notice: "Integracja została zaktualizowana."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account_integration.destroy
    redirect_to integrations_path, notice: "Integracja została usunięta."
  end

  def test
    if @account_integration.test_connection!
      redirect_to edit_account_integration_path(@account_integration), notice: "Połączenie z #{@account_integration.integration.name} zostało pomyślnie przetestowane i integracja została aktywowana!"
    else
      redirect_to edit_account_integration_path(@account_integration), alert: "Test połączenia nie powiódł się: #{@account_integration.error_message || 'Sprawdź dane logowania.'}"
    end
  end

  private

  def permitted_stores(config)
    stores = Hash.new { |h, k| h[k] = [] }

    config[:schema].each do |section|
      store = section[:store].to_sym
      next unless section[:fields]

      section[:fields].each do |key, field|
        type = field[:type].to_s
        if %w[payment_method_mapping mapping key_value].include?(type)
          stores[store] << { key => {} }
        else
          stores[store] << key
        end
      end
    end

    stores
  end

  def account_integration_params
    integration_key =
      @account_integration&.integration&.key ||
      params[:provider] ||
      Integration.find_by(id: params.dig(:account_integration, :integration_id))&.key

    config = load_config_for(integration_key) || { schema: [] }
    stores = permitted_stores(config)

    params.require(:account_integration).permit(
      :name,
      :integration_id,
      credentials: stores[:credentials],
      settings:    stores[:settings],
    )
  end

  def set_account_integration
    @account_integration = current_account.account_integrations.find(params[:id])
  end

  def should_merge_credentials?
    params.dig(:account_integration, :credentials).present?
  end

  def merge_credentials
    new_creds = account_integration_params[:credentials]
    existing_creds = (@account_integration.credentials || {}).stringify_keys

    # Only update non-blank values
    new_creds.each do |key, value|
      existing_creds[key.to_s] = value if value.present?
    end

    @account_integration.credentials = existing_creds
  end

  def load_config
    @config = load_config_for(@account_integration.integration.key) || { schema: [] }
  end

  def load_config_for(key)
    Integrations::ConfigLoader.load(key)
  rescue Errno::ENOENT
    nil
  end

  # FOR INVOICING INTEGRATIONS
  def prepare_payment_methods_data
    @order_payment_methods = current_account.orders
      .where.not(payment_method: [ nil, "" ])
      .distinct
      .pluck(:payment_method)
      .compact
      .sort

      adapter = @account_integration.adapter

      @integration_payment_methods =
        if adapter.respond_to?(:payment_methods)
          adapter.payment_methods || []
        else
          []
        end

      if @integration_payment_methods.blank? && @account_integration.integration&.key == "fakturownia"
        @integration_payment_methods = Integrations::Invoicing::FakturowniaAdapter.available_payment_methods
      end
  end
end
