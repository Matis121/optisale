class FiltersComponent < ViewComponent::Base
  include FiltersHelper

  def initialize(query:, url:, turbo_frame: nil, id: "filters-form", preserve_params: {})
    @query = query
    @url = url
    @turbo_frame = turbo_frame
    @id = id
    @preserve_params = preserve_params
  end

  private

  attr_reader :query, :url, :turbo_frame, :id, :preserve_params
end
