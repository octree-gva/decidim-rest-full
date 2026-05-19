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
