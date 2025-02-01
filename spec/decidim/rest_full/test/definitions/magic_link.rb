# frozen_string_literal: true

module Api
  module Definitions
    MAGIC_LINK = {
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
            self: Api::Definitions.link("Magic Link Creation"),
            sign_in: Api::Definitions.link("Sign in")
          },
          required: [:self, :sign_in]
        }
      },
      required: [:attributes, :links, :id, :type],
      additionalProperties: false
    }.freeze
  end
end
