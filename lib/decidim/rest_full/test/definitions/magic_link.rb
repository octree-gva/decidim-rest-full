# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:magic_link) do
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
          label: { type: :string, description: "Magic Link description" },
          redirect_url: {
            type: :string,
            nullable: true,
            description: "If set at create time, the GET sign-in flow redirects here after successful sign-in (HTTPS, allowlisted host)"
          }
        },
        required: [:token, :label]
      },
      links: {
        type: :object,
        title: "Magic Link links",
        properties: {
          self: Decidim::RestFull::Core::DefinitionRegistry.resource_link,
          sign_in: Decidim::RestFull::Core::DefinitionRegistry.resource_link
        },
        required: [:self, :sign_in]
      }
    },
    required: [:attributes, :links, :id, :type],
    additionalProperties: false
  }.freeze
end
