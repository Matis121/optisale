class Storage::StockMovementsController < ApplicationController
  before_action :set_product, only: [ :index ]

  def index
    @warehouse = params[:warehouse_id].present? ?
                 Warehouse.find(params[:warehouse_id]) :
                 nil

    @q = @product.stock_movements
                 .includes(:warehouse, :user, :reference)

    # Filter by warehouse if provided
    @q = @q.for_warehouse(@warehouse) if @warehouse

    @q = @q.ransack(params[:q])
    @stock_movements = @q.result
                        .recent
                        .page(params[:page])
                        .per(20)

    respond_to do |format|
      format.html { render layout: false if turbo_frame_request? }
      format.turbo_stream
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end
end
