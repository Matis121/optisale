module StockHelper
  def stock_status_badge(quantity)
    case quantity
    when 0
      content_tag :span, "Brak", class: "badge badge-error badge-sm"
    when 1..10
      content_tag :span, "Niski", class: "badge badge-warning badge-sm"
    when 11..50
      content_tag :span, "Średni", class: "badge badge-info badge-sm"
    else
      content_tag :span, "Wysoki", class: "badge badge-success badge-sm"
    end
  end


  def movement_type_badge(movement_type)
    case movement_type
    when "order_placement"
      content_tag :span, "Zamówienie", class: "badge badge-primary badge-outline badge-xs"
    when "stock_in"
      content_tag :span, "Przyjęcie", class: "badge badge-success badge-outline badge-xs"
    when "stock_out"
      content_tag :span, "Wydanie", class: "badge badge-error badge-outline badge-xs"
    when "manual_adjustment"
      content_tag :span, "Korekta", class: "badge badge-warning badge-outline badge-xs"
    when "damage"
      content_tag :span, "Uszkodzenie", class: "badge badge-error badge-outline badge-xs"
    when "return"
      content_tag :span, "Zwrot", class: "badge badge-info badge-outline badge-xs"
    else
      content_tag :span, movement_type.humanize, class: "badge badge-neutral badge-outline badge-xs"
    end
  end

  def quantity_change_indicator(quantity)
    if quantity > 0
      content_tag :span, "+#{quantity}", class: "text-success font-mono"
    else
      content_tag :span, quantity.to_s, class: "text-error font-mono"
    end
  end
end
