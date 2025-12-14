module IntegrationsHelper
  # Returns an asset path for integration logo if it exists (png/svg).
  # Convention:
  # - app/assets/images/integrations/<key>.png
  # - app/assets/images/integrations/<key>.svg
  # Backward-compatible fallbacks:
  # - app/assets/images/<key>.png
  # - app/assets/images/<key>.svg
  def integration_logo_asset_path(integration_key)
    key = integration_key.to_s
    candidates = [
      "integrations/#{key}.png",
      "integrations/#{key}.svg",
      "#{key}.png",
      "#{key}.svg"
    ]

    candidates.each do |relative|
      full = Rails.root.join("app/assets/images", relative)
      return relative if File.exist?(full)
    end

    nil
  end
end
