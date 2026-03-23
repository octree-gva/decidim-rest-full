# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:comment_reaction) do
  {
    type: :object,
    title: "CommentReaction",
    properties: {
      id: { type: :string, description: "Comment vote id" },
      type: { type: :string, enum: ["comment_reaction"] },
      attributes: {
        type: :object,
        properties: {
          weight: { type: :integer, enum: [-1, 1] },
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) }
        },
        additionalProperties: true
      },
      relationships: { type: :object, additionalProperties: true },
      links: {
        type: :object,
        properties: {
          self: Decidim::RestFull::Core::DefinitionRegistry.resource_link
        },
        additionalProperties: true
      }
    },
    required: [:id, :type, :attributes],
    additionalProperties: true
  }.freeze
end
