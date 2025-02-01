# frozen_string_literal: true

module Api
  module Definitions
    MAGIC_LINK_REDIRECT = {
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
            self: Api::Definitions.link("Sign in"),
            magic_link: Api::Definitions.link("Magic Link Creation")
          },
          required: [:self, :magic_link]
        }
      },
      required: [:attributes, :links, :id, :type],
      additionalProperties: false
    }.freeze
  end
end
