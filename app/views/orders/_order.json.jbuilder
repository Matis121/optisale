json.extract! order, :id, :user_id, :source, :status, :order_date, :total_amount, :currency, :created_at, :updated_at
json.url order_url(order, format: :json)
