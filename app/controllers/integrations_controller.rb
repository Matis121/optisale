class IntegrationsController < ApplicationController
  before_action :set_integrations, only: :index

  def index
  end

  private


  def set_integrations
    @integrations = Integration.all
  end
end
