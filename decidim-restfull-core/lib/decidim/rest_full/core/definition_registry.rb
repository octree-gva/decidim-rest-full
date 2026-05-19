# frozen_string_literal: true

require_relative "swagger_spec_paths"

module Decidim
  module RestFull
    module Core
      # Singleton that holds OpenAPI 3 schema definitions (OpenAPI +components/schemas+; not Decidim::Component).
      # Used by request specs (RSwag) and +swagger_helper+ metadata. Definitions are registered
      # via register_object, register_resource, etc. Link helpers (get_action_link,
      # post_action_link, resource_link) are registered in register_link_helpers.
      #
      # Component **resource** schemas (JSON:API +type+ for participatory components) align with
      # +Decidim::ComponentManifest#name+ via +register_component_manifest_schema+.
      class DefinitionRegistry
        include Singleton

        def initialize
          @schema = {}
          @openapi_component_manifest_schema_by_name = {}
          @openapi_component_manifest_schema_order = []
          @openapi_component_resource_schema_finalized = false
          register_link_helpers
        end

        # +Decidim::ComponentManifest+ +:name+ values (e.g. +"proposals"+) that ship a dedicated
        # OpenAPI schema for this manifest's JSON:API component resource (+proposal_component+, …).
        def component_manifest_names_with_openapi_schema
          @openapi_component_manifest_schema_by_name.keys
        end

        # Binds a +Decidim::ComponentManifest+ (+manifest:+ matches +manifest.name+, e.g. +:blogs+ or +"blogs"+)
        # to the OpenAPI schema name for that manifest’s component resource (+schema_name:+ e.g. +:blog_component+).
        # Used to build the polymorphic +:component+ +oneOf+ and to omit this manifest from +:other_component+ enums.
        def register_component_manifest_schema(manifest:, schema_name:)
          name = manifest.to_s
          sym = schema_name.to_sym
          @openapi_component_manifest_schema_by_name[name] = sym
          @openapi_component_manifest_schema_order << sym unless @openapi_component_manifest_schema_order.include?(sym)
        end

        # Builds +:other_component+, the polymorphic JSON:API +:component+ OpenAPI schema (+oneOf+), and response
        # wrappers. Run after all +register_component_manifest_schema+ calls (see +definitions.rb+ load order).
        def finalize_openapi_component_resource_schema!
          raise ArgumentError, "OpenAPI component resource schema already finalized" if @openapi_component_resource_schema_finalized

          @openapi_component_resource_schema_finalized = true

          reserved_manifest_names = component_manifest_names_with_openapi_schema
          other_manifests = Decidim.component_registry.manifests.reject do |m|
            m.name.to_s == "dummy" || reserved_manifest_names.include?(m.name.to_s)
          end
          other_types = other_manifests.map { |cm| "#{cm.name.to_s.singularize}_component" }
          other_manifest_names = other_manifests.map { |cm| cm.name.to_s }

          extends_object(:other_component, :generic_component) do |other_component|
            other_component[:title] = "Generic Component"
            other_component[:properties][:type] = { type: :string, enum: other_types }
            other_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: other_manifest_names }
            other_component
          end

          manifest_schema_refs = @openapi_component_manifest_schema_order.map { |n| { "$ref" => reference(n) } }
          one_of = manifest_schema_refs + [{ "$ref" => reference(:other_component) }]

          register_object(:component) do
            { oneOf: one_of }.freeze
          end
          register_response_for(:component)
        end

        # rubocop:disable Naming/PredicateName
        def has_many_relation(resource_type_schema, title: nil, description: nil, item_schema_key: nil)
          items_schema = if item_schema_key
                           { "$ref" => reference(item_schema_key) }
                         else
                           {
                             type: :object,
                             title: "Has Many Relation Item",
                             properties: {
                               id: { type: :string, description: "Resource Id" },
                               type: resource_type_schema
                             },
                             required: [:id, :type]
                           }
                         end
          has_many_schema = {
            type: :object,
            title: "Has Many Relation",
            properties: {
              data: {
                type: :array,
                items: items_schema
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
          has_many_relation(item_schema, title:, description:, &block)
        end

        # rubocop:enable Naming/PredicateName
        def belongs_to_relation(resource_type_schema, title: nil, description: nil)
          belongs_to_schema = {
            title: "Belongs To Relation",
            type: :object,
            properties: {
              data: {
                type: :object,
                title: "Belongs To Relation Item",
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
          belongs_to_relation(item_schema, title:, description:, &block)
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
              title: "#{name_sym.to_s.titleize} Item Response",
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

        ##
        # Merge additional relationship keys into an existing +register_resource+ schema
        # (additive; used from test definition files, not from +Extension#rest_enhancement+).
        # @param resource_name [Symbol] e.g. +:proposal+
        # @param new_relationship_schemas [Hash] relationship_name => OpenAPI fragment (same shape as DefinitionRegistry helpers)
        # @raise [ArgumentError] if the resource or relationships.properties path is missing, or the key already exists
        def add_resource_relationships(resource_name, **new_relationship_schemas)
          name_sym = resource_name.to_sym
          raise ArgumentError, "Schema `#{name_sym}` is not registered" unless @schema.has_key?(name_sym)

          rel_props = @schema[name_sym].dig(:properties, :relationships, :properties)
          raise ArgumentError, "Schema `#{name_sym}` has no relationships.properties to extend" unless rel_props

          new_relationship_schemas.each do |key, schema|
            k = key.to_sym
            raise ArgumentError, "Relationship key #{key.inspect} already exists on #{name_sym}" if rel_props.has_key?(k) || rel_props.has_key?(key.to_s)

            rel_props[k] = schema
          end
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

        # Register link schemas used in OpenAPI (get_action_link, post_action_link, resource_link).
        def register_link_helpers
          register_get_action_link_schema
          register_post_action_link_schema
          register_resource_link_schema
        end

        def register_get_action_link_schema
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
        end

        def register_post_action_link_schema
          register_object :post_action_link do
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
                    action_target: { type: :string, description: "URL to open after submitting a valid request" }
                  },
                  required: [:action_method, :action_enctype],
                  additionalProperties: false
                }
              },
              required: [:href, :title, :meta, :rel]
            }
          end
        end

        def register_resource_link_schema
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
          delegate :add_resource_relationships, to: :instance
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
          delegate :register_component_manifest_schema, :finalize_openapi_component_resource_schema!, :component_manifest_names_with_openapi_schema,
                   to: :instance

          def register_swagger_spec_path(*globs)
            SwaggerSpecPaths.register(*globs)
          end

          def register_open_api_definition_path(*paths)
            OpenApiDefinitionPaths.register(*paths)
          end
        end
      end
    end
  end
end
