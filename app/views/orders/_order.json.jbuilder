json.extract! order, :id, :user_id, :source, :status, :order_date, :currency, :created_at, :updated_at
json.url order_url(order, format: :json)
