# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:forms_locale_meta) do
  {
    type: :object,
    title: "Forms locale metadata",
    properties: {
      locale: { type: :string, description: "Effective locale for projected strings" },
      requested_locale: { type: :string, description: "Client-requested locale before fallback" },
      fallback_from: { type: :string, nullable: true, description: "Locale downgraded from, if any" }
    },
    required: [:locale, :requested_locale],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:forms_collection_meta) do
  {
    type: :object,
    title: "Forms collection pagination and locale metadata",
    properties: {
      page: { type: :integer, minimum: 1 },
      per_page: { type: :integer, minimum: 1, maximum: 100 },
      has_more: {
        type: :boolean,
        description: "True when another page may exist (limit+1). Always true when order=rand."
      },
      next: { type: :string, nullable: true },
      prev: { type: :string, nullable: true },
      locale: { type: :string, description: "Effective locale for projected strings" },
      requested_locale: { type: :string, description: "Client-requested locale before fallback" },
      fallback_from: { type: :string, nullable: true, description: "Locale downgraded from, if any" }
    },
    required: [:page, :per_page, :has_more, :locale, :requested_locale],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:forms_submission_policy_meta) do
  {
    type: :object,
    title: "Questionnaire submission policy",
    properties: {
      allows_anonymous: { type: :boolean },
      requires_participant_ip: { type: :boolean }
    },
    required: [:allows_anonymous, :requires_participant_ip],
    additionalProperties: false
  }
end
