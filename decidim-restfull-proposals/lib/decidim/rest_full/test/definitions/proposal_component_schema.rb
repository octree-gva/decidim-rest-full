# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_component_manifest_schema(manifest: :proposals, schema_name: :proposal_component)

Decidim::RestFull::Core::DefinitionRegistry.extends_object(:proposal_component, :generic_component) do |proposal_component|
  proposal_component[:title] = "Proposal Component"
  proposal_component[:description] = <<~README
    A proposal component can host proposals from participants, and official proposals (proposals from the organization).
    This component have many metadatas that explain what are the restrictions regarding proposing, voting, commenting, amending or endorsing.#{" "}

    Features toggles:#{" "}
    - `can_create_proposals`: If participants can create proposals
    - `can_vote`: If voting is enabled for the component (and, when impersonating, if unvoted votable proposals remain)
    - `awesome_votes_enabled_by_status`: Decidim Awesome step setting — restrict voting by proposal status
    - `awesome_votes_enabled_states`: Allowed proposal state tokens when status restriction is on
    - `can_comment`: If participants can comments
    - .... and some more


  README
  proposal_component[:properties][:type] = { type: :string, enum: ["proposal_component"] }
  proposal_component[:properties][:attributes][:properties][:manifest_name] = { type: :string, enum: ["proposals"] }
  proposal_component[:properties][:links][:properties][:draft] = Decidim::RestFull::Core::DefinitionRegistry.resource_link
  additional_properties = {
    can_create_proposals: { type: :boolean, description: "If the current user can create proposal (component allows, and user did not reach publication limit)" },
    can_vote: {
      type: :boolean,
      description: "If voting is enabled for the component (votes_enabled and not votes_blocked; " \
                   "when impersonating, also requires unvoted votable proposals)"
    },
    awesome_votes_enabled_by_status: {
      type: :boolean,
      description: "Decidim Awesome step setting: when true, voting is restricted to proposals whose status is listed in awesome_votes_enabled_states"
    },
    awesome_votes_enabled_states: {
      type: :array,
      items: { type: :string },
      description: "Allowed proposal state tokens when awesome_votes_enabled_by_status is true (e.g. accepted, evaluating, not_answered)"
    },
    can_comment: { type: :boolean, description: "If the current user can comment on the component" },
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
      description: <<~DESC.squish,
        Always present (never null). Empty array when votes are not available (`votes_enabled` false).
        When votes are enabled: simple vote ([1] or [0,1] with abstention), or voting cards ([1,2,3] or [0,1,2,3]).
        Independent of `can_vote` (per-actor flag).
      DESC
      type: :array,
      items: {
        type: :object,
        title: "Proposal Vote Weight",
        properties: {
          label: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop), :description => "Label to voting button" },
          weight: { type: :integer, description: "Value to add to the vote. 0 for abstention" }
        },
        required: [:label, :weight]
      }
    },
    awesome_voting_manifest: {
      type: :string,
      description: "Decidim Awesome weighted voting manifest (e.g. empty/default or voting_cards). Present when Awesome weighted voting is enabled."
    },
    voting_cards_show_abstain: {
      type: :boolean,
      description: "Decidim Awesome: include abstention (weight 0) in vote options."
    },
    voting_cards_show_modal_help: {
      type: :boolean,
      description: "Decidim Awesome: show voting help modal."
    },
    voting_cards_box_title: {
      "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop),
      :description => "Decidim Awesome: title for the voting box."
    },
    voting_cards_instructions: {
      "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop),
      :description => "Decidim Awesome: voting instructions (help modal)."
    }
  }
  proposal_component[:properties][:meta][:properties].merge!(additional_properties)
  proposal_component[:properties][:meta][:required].push(
    :can_create_proposals, :can_vote, :can_comment, :geocoding_enabled, :attachments_allowed, :vote_limit, :votes,
    :awesome_votes_enabled_by_status, :awesome_votes_enabled_states
  )
  proposal_component
end
Decidim::RestFull::Core::DefinitionRegistry.register_response_for(:proposal_component)
