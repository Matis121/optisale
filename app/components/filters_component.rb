class FiltersComponent < ViewComponent::Base
  include FiltersHelper

  def initialize(query:, url:, turbo_frame: nil, id: "filters-form")
    @query = query
    @url = url
    @turbo_frame = turbo_frame
    @id = id
  end

  private

  attr_reader :query, :url, :turbo_frame, :id
end
