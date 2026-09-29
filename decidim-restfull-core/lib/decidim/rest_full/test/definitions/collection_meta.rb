# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:collection_meta) do
  {
    type: :object,
    title: "Collection pagination metadata",
    properties: {
      page: { type: :integer, minimum: 1, description: "Current page (1-based)" },
      per_page: { type: :integer, minimum: 1, maximum: 100, description: "Page size (default 20, max 100)" },
      has_more: { type: :boolean, description: "True when another page exists (limit+1, no COUNT)" },
      next: { type: :string, nullable: true, description: "Absolute URL for the next page, or null" },
      prev: { type: :string, nullable: true, description: "Absolute URL for the previous page, or null" }
    },
    required: [:page, :per_page, :has_more],
    additionalProperties: false
  }
end
