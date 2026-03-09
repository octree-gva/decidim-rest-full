# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:organization_extended_data) do
  {
    type: :object,
    title: "Organization extended data",
    properties: {},
    additionalProperties: true,
    description: <<~README
      Hash of values attached to an organization. These values won't be
      displayed to admins or users, consider this as an internal
      data payload.
    README
  }.freeze
end
