class Ui::Order::AddProductModalComponent < ViewComponent::Base
  def initialize(order:, current_user:)
    @order = order
    @current_user = current_user
  end

  private

  attr_reader :order, :current_user
end
