# frozen_string_literal: true

module Decidim
  module RestFull
    class DefinitionRegistry
      include Singleton

      def initialize
        @schema = {}
        register_link_helpers
      end

      # rubocop:disable Naming/PredicateName
      def has_many_relation(resource_type_schema, title: nil, description: nil)
        has_many_schema = {
          type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :string, description: "Resource Id" },
                  type: resource_type_schema
                },
                required: [:id, :type]
              }
            }
          },
          required: [:data]
        }
        has_many_schema[:title] = title if title.present?
        has_many_schema[:properties][:data][:title] = "#{title} Data" if title.present?
        has_many_schema[:description] = description if description.present?
        return yield(has_many_schema) if block_given?

        has_many_schema
      end

      ##
      # Create an Open Api Schema for a has_many relationship
      # @param resource_types [Array<Symbol>] The resource types that are related to the current resource
      # @param title [String] The title of the relationship
      # @param description [String] The description of the relationship
      # @return [Hash] The Open Api Schema for the relationship
      def has_many(*resource_types, title: nil, description: nil, &block)
        unless resource_types.all? { |type| type.is_a?(String) || type.is_a?(Symbol) }
          raise ArgumentError, "Resource types must be strings or symbols, got: #{resource_types.inspect}"
        end

        item_schema = { type: :string }
        item_schema[:enum] = resource_types.map(&:to_s) unless resource_types.empty?
        has_many_relation(item_schema, title: title, description: description, &block)
      end

      # rubocop:enable Naming/PredicateName
      def belongs_to_relation(resource_type_schema, title: nil, description: nil)
        belongs_to_schema = {
          type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                id: { type: :string, description: "Resource Id" },
                type: resource_type_schema
              },
              required: [:id, :type]
            }
          },
          required: [:data]
        }
        belongs_to_schema[:title] = title if title.present?
        belongs_to_schema[:properties][:data][:title] = "#{title} Data" if title.present?
        belongs_to_schema[:description] = description if description.present?
        return yield(belongs_to_schema) if block_given?

        belongs_to_schema
      end

      ##
      # Create an Open Api Schema for a belongs_to relationship
      # @param resource_types [Array<Symbol>] The resource types that are related to the current resource
      # @param title [String] The title of the relationship
      # @param description [String] The description of the relationship
      # @return [Hash] The Open Api Schema for the relationship
      def belongs_to(*resource_types, title: nil, description: nil, &block)
        # Validate resource_types
        unless resource_types.all? { |type| type.is_a?(String) || type.is_a?(Symbol) }
          raise ArgumentError, "Resource types must be strings or symbols, got: #{resource_types.inspect}"
        end

        item_schema = { type: :string }
        item_schema[:enum] = resource_types.map(&:to_s) unless resource_types.empty?
        belongs_to_relation(item_schema, title: title, description: description, &block)
      end

      ##
      # Register an Open Api Schema
      # @param name [Symbol] The name of the schema
      # @param block [Proc] The block that defines the schema
      # @return [Hash] The Open Api Schema
      def register_object(name)
        name_sym = :"#{name}"
        raise "Schema #{name_sym} already registered" if @schema.has_key?(name_sym)

        @schema[name_sym] = yield
      end

      ##
      # Register an Open Api Schema that extends another schema
      # @param name [Symbol] The name of the schema
      # @param parent [Symbol] The parent schema
      # @param block [Proc] The block that defines the schema
      # @return [Hash] The Open Api Schema
      def extends_object(name, parent)
        raise "Schema #{name} already registered" if @schema.has_key?(name)

        parent = @schema[parent].deep_dup
        parent_title = parent[:title]
        extended_object = yield(parent)
        # To have uniq typing, we need to replace the title of the extended object with the name of the extended object
        title = extended_object[:title]
        title = name.to_s.titleize if title == parent_title
        extended_object = extended_object.deep_transform_values do |value|
          if value.is_a? String
            value.gsub(parent_title, title)
          else
            value
          end
        end
        extended_object[:title] = title
        @schema[name] = extended_object
      end

      def register_response_for(name)
        name_sym = :"#{name}"

        register_object("#{name_sym}_index_response") do
          {
            type: :object,
            title: "#{name_sym.to_s.titleize} Index Response",
            properties: {
              data: {
                type: :array,
                items: { "$ref" => reference(name_sym) }
              }
            },
            required: [:data]
          }
        end
        register_object("#{name_sym}_item_response") do
          {
            type: :object,
            title: "#{name_sym.to_s.titleize} Index Response",
            properties: {
              data: {
                "$ref" => reference(name_sym)
              }
            },
            required: [:data]
          }
        end
      end

      ##
      # Register an Open Api Schema for a resource. Will add the index and item response schemas.
      # @param name [Symbol] The name of the schema
      # @param block [Proc] The block that defines the schema
      # @return [void]
      def register_resource(name)
        name_sym = :"#{name}"

        raise "Schema #{name_sym} already registered" if @schema.has_key?(name_sym)

        @schema[name_sym] = yield
        register_response_for(name_sym)
      end

      def resource_link
        {
          "$ref": reference(:resource_link)
        }
      end

      def post_action_link
        {
          "$ref": reference(:post_action_link)
        }
      end

      # rubocop:disable Naming/AccessorMethodName
      def get_action_link
        {
          "$ref": reference(:get_action_link)
        }
      end
      # rubocop:enable Naming/AccessorMethodName

      ##
      # Get the reference to a registered schema
      # @param name [Symbol] The name of the schema
      # @return [String|nil] The reference to the schema or nil if the schema is not registered
      def reference(name)
        unless @schema.has_key?(name)
          suggestions = DidYouMean::SpellChecker.new(dictionary: @schema.keys).correct(name)
          message = "Schema `#{name}` not yet registered"
          message += ". Did you mean: #{suggestions.map { |s| "`#{s}`" }.join(", ")} ?" if suggestions.any?
          raise ArgumentError, message
        end

        "#/components/schemas/#{name}"
      end

      def schema_for(name)
        unless @schema.has_key?(name)
          suggestions = DidYouMean::SpellChecker.new(dictionary: @schema.keys).correct(name)
          message = "Schema `#{name}` not yet registered"
          message += ". Did you mean: #{suggestions.map { |s| "`#{s}`" }.join(", ")} ?" if suggestions.any?
          raise ArgumentError, message
        end

        @schema[name]
      end

      def references
        @schema.keys.map { |name| reference(name) }
      end

      ##
      # Get the open api v3 schema as a hash
      # @return [Hash] The schema
      def as_json
        @schema
      end

      private

      ##
      # Register helpers objects used to generate the open api v3 schema
      # @return [void]
      def register_link_helpers
        register_object :get_action_link do
          {
            title: "GET Action URL",
            type: :object,
            properties: {
              title: { type: :string, description: "Action Name" },
              href: { type: :string, description: "Full URL" },
              describedby: { type: :string, description: "JSONSchema URL describing the request" },
              hreflang: { type: :array, items: { type: :string }, description: "Available locales" },
              rel: { type: :string, enum: ["action"] },
              meta: {
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
              }
            },
            required: [:href, :title, :meta, :rel]
          }
        end

        register_object :post_action_link do
          {
            title: "POST/DELETE/PUT Action URL",
            type: :object,
            properties: {
              title: { type: :string, description: "Action Name" },
              href: { type: :string, description: "Full URL" },
              describedby: { type: :string, description: "JSONSchema URL describing the request" },
              hreflang: { type: :array, items: { type: :string }, description: "Available locales" },
              rel: { type: :string, enum: ["action"] },
              meta: {
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

            },
            required: [:href, :title, :meta, :rel]
          }
        end

        register_object :resource_link do
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
                title: "Resource URL Metadata",
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
          }
        end
      end

      class << self
        # Expose singleton methods as static methods
        delegate :register_object, to: :instance
        delegate :register_response_for, to: :instance
        delegate :extends_object, to: :instance
        delegate :register_resource, to: :instance
        delegate :has_many, to: :instance
        delegate :has_many_relation, to: :instance
        delegate :belongs_to, to: :instance
        delegate :belongs_to_relation, to: :instance
        delegate :resource_link, to: :instance
        delegate :post_action_link, to: :instance
        delegate :get_action_link, to: :instance
        delegate :reference, to: :instance
        delegate :references, to: :instance
        delegate :schema_for, to: :instance
        delegate :as_json, to: :instance
      end
    end
  end
end
