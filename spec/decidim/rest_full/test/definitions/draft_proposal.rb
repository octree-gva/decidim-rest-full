# frozen_string_literal: true

module Api
  module Definitions
    DRAFT_PROPOSAL = {
      type: :object,
      title: "Draft Proposal",
      properties: {
        id: { type: :string, description: "Draft Proposal Id" },
        type: { type: :string, enum: ["draft_proposal"] },
        attributes: {
          type: :object,
          properties: {
            title: {
              "$ref" => "#/components/schemas/translated_prop",
              description: "Draft Proposal title"
            },
            body: {
              "$ref" => "#/components/schemas/translated_prop",
              description: "Draft Proposal content"
            },
            errors: {
              type: :object,
              properties: {
                title: {
                  type: :array,
                  items: { type: :string }
                },
                body: {
                  type: :array,
                  items: { type: :string }
                }
              },
              required: [:title, :body],
              description: "Draft current errors"
            },
            created_at: { "$ref" => "#/components/schemas/creation_date" },
            updated_at: { "$ref" => "#/components/schemas/edition_date" }
          },
          required: [:created_at, :updated_at, :title, :body],
          additionalProperties: false
        },
        meta: {
          type: :object,
          title: "Draft Proposition Metadata",
          properties: {
            publishable: { type: :boolean, description: "Draft is published as it is now?" },
            client_id: { type: :string, description: "Attached client_id" },
            scope: { type: :integer, description: "Scope Id" },
            fields: { type: :array, description: "Editable field names", items: { type: :string } }
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
          required: [:publishable, :client_id, :fields]
        },
        links: {
          type: :object,
          title: "Proposal Links",
          properties: {
            self: Api::Definitions.link("Draft Proposal Details"),
            collection: Api::Definitions.link("Proposal List"),
            related: Api::Definitions.link("Component Details")
          },
          additionalProperties: false,
          required: [:self, :related, :collection]
        },
        relationships: {
          type: :object,
          title: "Proposal Relationships",
          properties: {
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
              required: [:data]
            },
            component: {
              type: :object,
              properties: {
                data: {
                  type: :object,
                  properties: {
                    id: { type: :string, description: "Component Id" },
                    type: { "$ref" => "#/components/schemas/component_type" }
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
