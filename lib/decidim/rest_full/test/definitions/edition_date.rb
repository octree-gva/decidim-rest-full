# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:edition_date) do
  {
    title: "Last Update Date",
    description: "Last update date, in ISO8601 format.",
    type: :string,
    format: :date_time,
    example: "2024-12-12T20:34:56Z"
  }.freeze
end
