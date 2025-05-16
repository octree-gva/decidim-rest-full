# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_resource(:magic_link) do
  {
    type: :object,
    title: "Magic Link",
    properties: {
      id: { type: :string, description: "Magic Token ID" },
      type: { type: :string, enum: ["magic_link"] },
      attributes: {
        type: :object,
        title: "Magic Link Attributes",
        properties: {
          token: { type: :string, description: "Magic Link Token" },
          label: { type: :string, description: "Magic Link description" }
        },
        required: [:token, :label]
      },
      links: {
        type: :object,
        title: "Magic Link links",
        properties: {
          self: Decidim::RestFull::DefinitionRegistry.resource_link,
          sign_in: Decidim::RestFull::DefinitionRegistry.resource_link
        },
        required: [:self, :sign_in]
      }
    },
    required: [:attributes, :links, :id, :type],
    additionalProperties: false
  }.freeze
end
