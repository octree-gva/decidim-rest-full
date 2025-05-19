# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:creation_date) do
  {
    title: "Creation date",
    description: "Creation date, in ISO8601 format.",
    type: :string,
    format: :date_time,
    example: "2024-11-12T12:34:56Z"
  }.freeze
end
