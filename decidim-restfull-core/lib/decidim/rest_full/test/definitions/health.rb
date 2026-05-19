# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:health) do
  {
    type: :object,
    title: "Health Status",
    description: "Simple health payload with `message` of `OK` or `ERROR`.",
    properties: {
      message: { type: :string, enum: %w(OK ERROR), description: "Overall health flag" }
    }
  }.freeze
end
