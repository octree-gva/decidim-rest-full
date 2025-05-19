# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:space_type) do
  {
    type: :string,
    enum: Decidim.participatory_space_registry.manifests.map(&:name)
  }.freeze
end

Decidim::RestFull::DefinitionRegistry.register_object(:space_classes) do
  {
    type: :string,
    description: "space class name. Part of the polymorphic association (participatory_space_type,participatory_space_id)",
    enum: Decidim.participatory_space_registry.manifests.map(&:model_class_name)
  }.freeze
end

Decidim::RestFull::DefinitionRegistry.register_resource(:space) do
  {
    type: :object,
    title: "Space",
    properties: {
      id: { type: :string, description: "Space Id" },
      type: { type: :string, enum: ["space"] },
      attributes: {
        title: "Space Attributes",
        type: :object,
        properties: {
          title: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
            title: "Title translations",
            description: "Space title"
          },
          subtitle: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
            title: "Subtitle translations",
            description: "Space subtitle"
          },
          short_description: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
            title: "Short Description translations",
            description: "Space short_description"
          },
          description: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
            title: "Description translations",
            description: "Space description"
          },
          manifest_name: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:space_manifest) },
          participatory_space_type: { type: :string, example: "Decidim::Assembly" },
          visibility: { type: :string, enum: %w(public transparent private), description: "Space visibility" },
          created_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:edition_date) }
        },
        required: [:title, :manifest_name, :visibility, :created_at, :updated_at],
        additionalProperties: false
      },
      relationships: {
        type: :object,
        title: "Space relationships",
        properties: {
          components: Decidim::RestFull::DefinitionRegistry.has_many_relation({
                                                                                "$ref" => "#/components/schemas/component_type"
                                                                              }, title: "Linked Components") do |components_schema|
                        components_schema[:properties][:meta] = {

                          title: "Attached Components Meta",
                          type: :object,
                          properties: {
                            count: { type: :integer, description: "Total count for components association" }
                          },
                          additionalProperties: false,
                          required: [:count]
                        }

                        components_schema[:properties][:links] = {
                          type: :object,
                          title: "Linked Components",
                          properties: {
                            self: Decidim::RestFull::DefinitionRegistry.resource_link,
                            related: Decidim::RestFull::DefinitionRegistry.resource_link
                          },
                          additionalProperties: false,
                          required: [:self]
                        }
                        components_schema[:required].push(:meta)
                        components_schema[:required].push(:links)
                        components_schema
                      end
        }
      },
      links: {
        type: :object,
        title: "Space Links",
        properties: {
          self: Decidim::RestFull::DefinitionRegistry.resource_link,
          related: Decidim::RestFull::DefinitionRegistry.resource_link
        },
        required: [:self, :related],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes, :links, :relationships]
  }.freeze
end
