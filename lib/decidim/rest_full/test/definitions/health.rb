# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:health) do
  {
    type: :object,
    title: "Health Status",
    properties: {
      message: { type: :string, enum: %w(OK ERROR) }
    }
  }.freeze
end
