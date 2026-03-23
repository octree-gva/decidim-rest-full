# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:comment) do
  {
    type: :object,
    title: "Comment",
    properties: {
      id: { type: :string, description: "Comment Id" },
      type: { type: :string, enum: ["comment"] },
      attributes: {
        type: :object,
        properties: {
          body: { type: :object, additionalProperties: { type: :string } },
          alignment: { type: :integer, enum: [-1, 0, 1] },
          depth: { type: :integer },
          replies_count: { type: :integer },
          commentable_type: { type: :string },
          commentable_id: { type: :string },
          root_commentable_type: { type: :string },
          root_commentable_id: { type: :string },
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) }
        },
        additionalProperties: true
      },
      meta: { type: :object, additionalProperties: true },
      links: {
        type: :object,
        properties: {
          self: Decidim::RestFull::Core::DefinitionRegistry.resource_link
        },
        additionalProperties: true
      },
      relationships: { type: :object, additionalProperties: true }
    },
    required: [:id, :type, :attributes],
    additionalProperties: true
  }.freeze
end
