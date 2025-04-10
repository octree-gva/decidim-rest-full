# frozen_string_literal: true

module Api
  module Definitions
    PROPOSAL = {
      type: :object,
      title: "Proposal",
      properties: {
        id: { type: :string, description: "Proposal Id" },
        type: { type: :string, enum: ["proposal"] },
        attributes: {
          type: :object,
          properties: {
            title: {
              "$ref" => "#/components/schemas/translated_prop",
              description: "Proposal title"
            },
            body: {
              "$ref" => "#/components/schemas/translated_prop",
              description: "Proposal content"
            },
            created_at: { "$ref" => "#/components/schemas/creation_date" },
            updated_at: { "$ref" => "#/components/schemas/edition_date" }
          },
          required: [:created_at, :updated_at, :title, :body],
          additionalProperties: false
        },
        meta: {
          type: :object,
          title: "Proposition Metadata",
          properties: {
            published: { type: :boolean, description: "Published blog post?" },
            scope: { type: :integer, description: "Scope Id" },
            voted: {
              type: :object,
              properties: {
                weight: { type: :integer, description: "Vote weight" }
              },
              required: [:weight],
              additionalProperties: false,
              nullable: true
            }
          },
          additionalProperties: {
            oneOf: [
              {
                type: :boolean
              },
              {
                type: :integer
              },
              {
                type: :string
              },
              {
                "$ref" => "#/components/schemas/translated_prop"
              }
            ]
          },
          required: [:published]
        },
        links: {
          type: :object,
          title: "Proposal Links",
          properties: {
            self: Api::Definitions.link("Proposal Detail"),
            collection: Api::Definitions.link("Proposal Lists"),
            related: Api::Definitions.link("Component Details"),
            prev: Api::Definitions.link("Prev proposal entry", [nil, {}]),
            next: Api::Definitions.link("Next proposal entry", [nil, {}])
          },
          additionalProperties: false,
          required: [:self, :collection, :related]
        },
        relationships: {
          type: :object,
          title: "Proposal Relationships",
          properties: {
            state: {
              type: :object,
              properties: {
                data: {
                  type: :object,
                  properties: {
                    id: { type: :string, description: "Proposal State id" },
                    type: { type: :string, enum: ["proposal_state"], description: "Proposal State Type" }
                  },
                  required: [:id, :type]
                },
                meta: {
                  type: :object,
                  properties: {
                    token: { type: :string, description: "Proposal State token" }
                  },
                  required: [:token]
                }
              },
              additionalProperties: false,
              required: [:data, :meta],
              nullable: true
            },
            space: {
              type: :object,
              properties: {
                data: {
                  type: :object,
                  properties: {
                    id: { type: :string, description: "Space Id" },
                    type: { "$ref" => "#/components/schemas/space_type" }
                  },
                  required: [:id, :type]
                }
              },
              required: [:data],
              additionalProperties: false
            },
            component: {
              type: :object,
              properties: {
                data: {
                  type: :object,
                  properties: {
                    id: { type: :string, description: "Component Id" },
                    type: { type: :string, enum: ["proposal_component"] }
                  },
                  required: [:id, :type]
                }
              },
              required: [:data]
            },
            author: {
              type: :object,
              properties: {
                id: { type: :string, description: "User Id" },
                type: { type: :string, enum: %w(user user_group) }
              },
              required: [:data],
              nullable: true
            },
            coauthors: {
              type: :object,
              properties: {
                data: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: { type: :string, description: "User Id" },
                      type: { type: :string, enum: %w(user user_group) }
                    },
                    required: [:id, :type]
                  }
                }
              },
              required: [:data]
            }
          },
          required: [:component, :space, :author],
          additionalProperties: false
        }
      },
      required: [:id, :type, :attributes, :meta, :links]
    }.freeze
  end
end
