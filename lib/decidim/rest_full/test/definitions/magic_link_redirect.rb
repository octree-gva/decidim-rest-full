# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:magic_link_redirect) do
  {
    type: :object,
    title: "Magic Redirect",
    properties: {
      id: { type: :string, description: "Magic Token ID" },
      type: { type: :string, enum: ["magic_link_redirect"] },
      attributes: {
        type: :object,
        title: "Magic Link Attributes",
        properties: {
          redirect_url: { type: :string, description: "Redirection destination" },
          label: { type: :string, description: "Magic Link description" }
        },
        required: [:redirect_url, :label]
      },
      links: {
        type: :object,
        title: "Magic Link links",
        properties: {
          self: Decidim::RestFull::DefinitionRegistry.get_action_link,
          magic_link: Decidim::RestFull::DefinitionRegistry.get_action_link
        },
        required: [:self, :magic_link]
      }
    },
    required: [:attributes, :links, :id, :type],
    additionalProperties: false
  }.freeze
end
