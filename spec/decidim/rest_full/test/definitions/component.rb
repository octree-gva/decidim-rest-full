# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:generic_component) do
  {
    type: :object,
    title: "Component",
    properties: {
      id: { type: :string, description: "Component Id" },
      type: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:component_type) },
      attributes: {
        type: :object,
        properties: {
          name: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
            description: "Component name"
          },
          global_announcement: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
            description: "Component annoucement (intro)"
          },
          participatory_space_type: {
            "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:space_classes)
          },
          participatory_space_id: { type: :string, description: "Associate space id. Part of the polymorphic association (participatory_space_type,participatory_space_id)" },
          created_at: { type: :string, description: "Creation date of the component" },
          updated_at: { type: :string, description: "Last update date of the component" }
        },
        required: [:created_at, :updated_at, :name, :manifest_name, :participatory_space_type, :participatory_space_id],
        additionalProperties: false
      },
      meta: {
        type: :object,
        title: "Component Metadata",
        properties: {
          published: { type: :boolean, description: "Published component?" },
          scopes_enabled: { type: :boolean, description: "Component handle scopes?" }
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
              "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop)
            }
          ]
        },
        required: [:published, :scopes_enabled]
      },
      links: {
        type: :object,
        title: "Component Links",
        properties: {
          self: Decidim::RestFull::DefinitionRegistry.resource_link,
          related: Decidim::RestFull::DefinitionRegistry.resource_link
        },
        additionalProperties: false,
        required: [:self]
      },
      relationships: {
        type: :object,
        title: "Component Relationships",
        properties: {
          resources: Decidim::RestFull::DefinitionRegistry.has_many_relation({
                                                                               type: :string
                                                                             }, title: "Component Linked Resources") do |component_schema|
                       component_schema[:properties][:meta] = {
                         type: :object,
                         title: "Component Linked Resources Metadata",
                         properties: {
                           count: { type: :integer, description: "Total count of resources" }
                         },
                         required: [:count]
                       }
                       component_schema[:required].push(:meta)
                       component_schema
                     end
        }
      }
    }
  }.freeze
end
Decidim::RestFull::DefinitionRegistry.extends_object(:proposal_component, :generic_component) do |proposal_component|
  proposal_component[:title] = "Proposal Component"
  proposal_component[:description] = <<~README
    A proposal component can host proposals from participants, and official proposals (proposals from the organization).
    This component have many metadatas that explain what are the restrictions regarding proposing, voting, commenting, amending or endorsing.#{" "}

    Features toggles:#{" "}
    - `can_create_proposals`: If participants can create proposals
    - `can_vote`: If participants can vote
    - `can_comment`: If participants can comments
    - .... and some more


  README
  proposal_component[:properties][:type] = { type: :string, enum: ["proposal_component"] }
  proposal_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["proposals"] }
  proposal_component[:properties][:links][:properties][:draft] = Decidim::RestFull::DefinitionRegistry.resource_link
  additional_properties = {
    can_create_proposals: { type: :boolean, description: "If the current user can create proposal (component allows, and user did not reach publication limit)" },
    can_vote: { type: :boolean, description: "If the current user can vote on the component" },
    can_comment: { type: :boolean, description: "If the current user comment on the component" },
    geocoding_enabled: { type: :boolean, description: "If the component needs a map to display its resources" },
    attachments_allowed: { type: :boolean, description: "If the component allows to attach files to resources" },
    collaborative_drafts_enabled: { type: :boolean, description: "If you can create collaborative draft for the proposal" },
    comments_enabled: { type: :boolean, description: "If you can comment on proposals" },
    comments_max_length: { type: :integer, description: "Characters limit for comment" },
    default_sort_order: { type: :string, enum: %w(
      random recent most_voted most_endorsed most_commented most_followed with_more_authors automatic default
    ), description: "Default order of proposals" },
    official_proposals_enabled: { type: :boolean, description: "If proposals can be official" },
    participatory_texts_enabled: { type: :boolean, description: "If proposals are based on a text modification" },
    proposal_edit_before_minutes: { type: :integer, description: "Time in minute participant can edit the proposal" },
    proposal_edit_time: { type: :string, enum: %w(infinite limited), description: "Type of restriction for proposal edition" },
    proposal_limit: { type: :integer, description: "Max proposal per participant. No maximum if value is 0" },
    resources_permissions_enabled: { type: :boolean, description: "If authorizations can be defined per proposal" },
    threshold_per_proposal: { type: :integer, description: "Threshold to compare similar proposals" },
    vote_limit: { type: :integer, description: "Max Number of vote per participant. 0 if no limit" },
    endorsements_enabled: { type: :boolean, description: "If endorsements are enabled" },
    votes_enabled: { type: :boolean, description: "If votes on proposal are enabled" },
    creation_enabled: { type: :boolean, description: "If participant can create proposal are enabled" },
    proposal_answering_enabled: { type: :boolean, description: "If officials can answer proposals" },
    amendment_creation_enabled: { type: :boolean, description: "If participant can propose an amendment to a proposal" },
    amendment_reaction_enabled: { type: :boolean, description: "If participant can react to an amendment of a proposal" },
    amendment_promotion_enabled: { type: :boolean, description: "If participant choose an amendment to replace their initial proposal" },
    votes: {
      title: "Proposal Vote Weights Options",
      description: "Vote weight, if can_vote is true.",
      type: :array,
      items: {
        type: :object,
        title: "Proposal Vote Weight",
        properties: {
          label: { type: :string, description: "Label to voting button" },
          weight: { type: :integer, description: "Value to add to the vote. 0 for abstention" }
        },
        required: [:label, :weight]
      }
    }
  }
  proposal_component[:properties][:meta][:properties].merge!(additional_properties)
  proposal_component[:properties][:meta][:required].push(:can_create_proposals, :can_vote, :can_comment, :geocoding_enabled, :attachments_allowed, :vote_limit)
  proposal_component
end
Decidim::RestFull::DefinitionRegistry.register_response_for(:proposal_component)

Decidim::RestFull::DefinitionRegistry.extends_object(:blog_component, :generic_component) do |blog_component|
  blog_component[:title] = "Blog Post Component"
  blog_component[:properties][:type] = { type: :string, enum: ["blog_component"] }
  blog_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["blogs"] }
  blog_component
end
Decidim::RestFull::DefinitionRegistry.register_response_for(:blog_component)

Decidim::RestFull::DefinitionRegistry.extends_object(:other_component, :generic_component) do |other_component|
  used = %w(proposals blogs)
  others = Decidim.component_registry.manifests.map { |manifest| manifest.name.to_s }.reject { |manifest_name| manifest_name.to_s == "dummy" || used.include?(manifest_name) }
  other_types = others.map { |manifest_name| "#{manifest_name.singularize}_component" }
  other_manifest_name = others.map(&:to_s)
  other_component[:title] = "Generic Component"
  other_component[:properties][:type] = { type: :string, enum: other_types }
  other_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: other_manifest_name }

  other_component
end

Decidim::RestFull::DefinitionRegistry.register_object(:component) do
  {
    oneOf: [
      { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:proposal_component) },
      { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:blog_component) },
      { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:other_component) }
    ]
  }.freeze
end
Decidim::RestFull::DefinitionRegistry.register_response_for(:component)
