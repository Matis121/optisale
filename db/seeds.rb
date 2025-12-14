# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
#

integrations = [
  {
    name: "Fakturownia",
    key: "fakturownia",
    integration_type: "invoicing",
    multiple_allowed: false,
    enabled: true,
    beta: true
  }
]

integrations.each do |attrs|
  Integration.find_or_create_by!(key: attrs[:key]) do |i|
    i.assign_attributes(attrs)
  end
end

puts "Seedowanie zakończone pomyślnie."
