# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:role_attributes) do
  {
    title: "Role Attributes",
    type: :object,
    properties: {
      user_id: {
        type: :integer,
        description: "ID of the user associated to the role (nullable for pending invitations)"
      },
      resource_id: {
        type: :integer,
        description: "ID of the resource (organization or participatory space) the role is attached to"
      },
      resource_type: {
        type: :string,
        description: "Type of the resource (e.g. Organization, Decidim::ParticipatoryProcess)"
      },
      type: {
        type: :string,
        description: "Kind of role",
        enum: %w(general_admin space_private_member space_administrator space_moderator space_valuator)
      },
      invited_at: {
        type: :string,
        format: :"date-time",
        nullable: true,
        description: "Invitation timestamp if the role was created via invitation"
      },
      accepted_invite: {
        type: :boolean,
        description: "Whether the invitation has been accepted"
      },
      created_at: {
        "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date)
      },
      updated_at: {
        "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date)
      }
    },
    required: [:type, :resource_id, :resource_type, :created_at],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:role) do
  {
    type: :object,
    title: "Role",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["role"] },
      attributes: {
        "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:role_attributes)
      }
    },
    required: [:id, :type, :attributes],
    additionalProperties: false
  }.freeze
end
