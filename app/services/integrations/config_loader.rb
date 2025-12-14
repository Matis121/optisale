class Integrations::ConfigLoader
  def self.load(key)
    path = Rails.root.join("config", "integrations", "#{key}.yml")
    YAML.load_file(path).deep_symbolize_keys
  end
end
