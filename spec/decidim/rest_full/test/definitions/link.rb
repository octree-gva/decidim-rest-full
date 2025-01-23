# frozen_string_literal: true

module Api
  module Definitions
    LINK_NULL = { type: :null }.freeze
    LINK_STRING = { type: :string }.freeze
    LINK_OBJECT = {
      oneOf: [
        {
          title: "Resource URL",
          type: :object,
          properties: {
            href: { type: :string, description: "Full URL" },
            title: { type: :string, description: "Page Title" },
            hreflang: { type: :array, items: { type: :string }, description: "Available locales" },
            describedby: { type: :string, description: "JSONSchema URL describing the request" },
            rel: { type: :string, enum: %w(public_page resource) },
            meta: {
              type: :object,
              properties: {
                component_id: { type: :string, description: "Component ID" },
                component_manifest: { type: :string, description: "Component manifest" },
                space_id: { type: :string, description: "Space ID" },
                space_manifest: { type: :string, description: "Space Manifest" },
                resource_id: { type: :string, description: "Resource ID" }
              }
            }
          },
          required: [:href, :title, :meta, :rel],
          additionalProperties: false
        },
        {
          title: "Action URL",
          type: :object,
          properties: {
            title: { type: :string, description: "Action Name" },
            href: { type: :string, description: "Full URL" },
            describedby: { type: :string, description: "JSONSchema URL describing the request" },
            hreflang: { type: :array, items: { type: :string }, description: "Available locales" },
            rel: { type: :string, enum: ["action"] },
            meta: {
              oneOf: [
                {
                  title: "Meta for read request",
                  type: :object,
                  properties: {
                    component_id: { type: :string, description: "Component ID" },
                    component_manifest: { type: :string, description: "Component manifest" },
                    space_id: { type: :string, description: "Space ID" },
                    space_manifest: { type: :string, description: "Space Manifest" },
                    resource_id: { type: :string, description: "Resource ID" },
                    action_method: { type: :string, enum: ["GET"], description: "Action HTTP method" }
                  },
                  required: [:action_method],
                  additionalProperties: false
                },
                {
                  title: "Meta for write request",
                  type: :object,
                  properties: {
                    component_id: { type: :string, description: "Component ID" },
                    component_manifest: { type: :string, description: "Component manifest" },
                    space_id: { type: :string, description: "Space ID" },
                    space_manifest: { type: :string, description: "Space Manifest" },
                    resource_id: { type: :string, description: "Resource ID" },
                    action_method: { type: :string, enum: %w(POST DELETE PUT), description: "Action HTTP method" },
                    action_enctype: { type: :string, enum: ["application/x-www-form-urlencoded", "multipart/form-data"], description: "Encoding of the payload" },
                    action_target: { type: :string, description: "URL to goes after submitting a valid request" }
                  },
                  required: [:action_method, :action_enctype],
                  additionalProperties: false
                }
              ]
            }
          },
          required: [:href, :title, :meta, :rel]
        }
      ]

    }.freeze

    def self.link(description, links = {})
      links = [links] unless links.is_a? Array
      link_schemas = links.map do |link|
        next { **LINK_NULL, description: description } if link.nil?
        next { **LINK_STRING, description: description } if link.is_a? String
        next { **LINK_OBJECT, description: description } if link.is_a? Hash

        raise "Link #{link} type is not supported"
      end

      return link_schemas.first if link_schemas.size == 1

      {
        oneOf: link_schemas
      }
    end
  end
end
