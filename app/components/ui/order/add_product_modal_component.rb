class Ui::Order::AddProductModalComponent < ViewComponent::Base
  def initialize(order:, current_account:)
    @order = order
    @current_account = current_account
  end

  private

  attr_reader :order, :current_account
end
