module FiltersHelper
  def filter_text(field, label, query, placeholder: nil)
    content_tag :div, class: "form-control flex flex-col gap-1" do
      concat content_tag(:label, class: "label") { content_tag(:span, label, class: "label-text text-xs") }
      concat text_field_tag("q[#{field}]", query&.send(field),
        placeholder: placeholder || "Wpisz #{label.downcase}...",
        class: "input input-sm input-bordered")
    end
  end

  def filter_number(field, label, query, placeholder: nil, step: nil)
    content_tag :div, class: "form-control flex flex-col gap-1" do
      concat content_tag(:label, class: "label") { content_tag(:span, label, class: "label-text text-xs") }
      concat number_field_tag("q[#{field}]", query&.send(field),
        placeholder: placeholder,
        step: step,
        class: "input input-sm input-bordered")
    end
  end

  def filter_date(field, label, query)
    content_tag :div, class: "form-control flex flex-col gap-1" do
      concat content_tag(:label, class: "label") { content_tag(:span, label, class: "label-text text-xs") }
      concat date_field_tag("q[#{field}]", query&.send(field),
        class: "input input-sm input-bordered")
    end
  end

  def filter_select(field, label, query, options: [], collection: nil, option_value: :id, option_text: :name, include_blank: "Wszystkie")
    content_tag :div, class: "form-control flex flex-col gap-1  " do
      concat content_tag(:label, class: "label") { content_tag(:span, label, class: "label-text text-xs") }

      if collection
        concat select_tag("q[#{field}]",
          options_from_collection_for_select(collection, option_value, option_text, query&.send(field)),
          { include_blank: include_blank, class: "select select-sm select-bordered" })
      else
        concat select_tag("q[#{field}]",
          options_for_select(options, query&.send(field)),
          { include_blank: include_blank, class: "select select-sm select-bordered" })
      end
    end
  end
end
