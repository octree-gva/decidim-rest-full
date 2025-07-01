# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:organization_attributes) do
  {
    title: "Organization Attributes",
    type: :object,
    properties: {
      name: {
        "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
        additionalProperties: { type: :string }
      },
      description: {
        "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:translated_prop),
        additionalProperties: { type: :string }
      },
      reference_prefix: { type: :string, description: "Prefix for the organization. Used to prefix uplodaded files and reference resources" },
      host: { type: :string },
      send_welcome_notification: { type: :boolean, description: "True if welcome email is sent to users" },
      secondary_hosts: { type: :array, items: { type: :string, description: "Additional host, will redirect (301) to `host`" } },
      available_locales: Decidim::RestFull::DefinitionRegistry.schema_for(:locales),
      default_locale: { type: :string, description: "defaut locale for the organization" },
      users_registration_mode: { type: :string, enum: %w(enabled existing disabled), description: <<~README
        Define user registration mode:#{" "}
        - `enabled`: Enable users registration
        - `existing`: Existing users will be able to login. Registration will be disabled.
        - `disabled`: No registration enabled
      README
      },
      force_users_to_authenticate_before_access_organization: { type: :boolean, description: "Force users to authenticate before accessing the organization (disabled if users_registration_mode is `disabled`)" },
      badges_enabled: { type: :boolean, description: "Enable badges for public views" },
      enable_participatory_space_filters: { type: :boolean, description: "Display areas and scopes filter in public views." },
      enable_machine_translations: { type: :boolean, description: "Enable machine translations (must be configured, see [Using machine translations](https://docs.decidim.org/en/develop/develop/machine_translations.html))" },
      user_groups_enabled: { type: :boolean, description: "Enable user groups in public views" },
      time_zone: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:time_zone) },
      comments_max_length: { type: :integer, description: "Default maximum length of comments" },
      rich_text_editor_in_public_views: { type: :boolean, description: "Enable rich text editor in public views" },
      created_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:creation_date) },
      updated_at: { "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:edition_date) },
      extended_data: { type: :object, description: "Extended data for the organization" }
    },
    additionalProperties: false,
    required: [:host, :name, :available_locales, :default_locale]
  }
end

Decidim::RestFull::DefinitionRegistry.register_resource(:organization) do
  {
    type: :object,
    title: "Organization",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["organization"] },
      attributes: {
        "$ref" => Decidim::RestFull::DefinitionRegistry.reference(:organization_attributes)
      },
      meta: {
        title: "Organization Metadata",
        type: :object,
        properties: {
          locales: Decidim::RestFull::DefinitionRegistry.schema_for(:locales),
          unconfirmed_host: { type: :string, description: "If host update is pending, unconfirmed host for the organization" }
        },
        required: [:locales],
        additionalProperties: false
      }
    },
    required: [:id, :type, :attributes, :meta]
  }.freeze
end
