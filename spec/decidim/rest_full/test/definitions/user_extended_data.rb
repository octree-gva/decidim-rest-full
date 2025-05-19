# frozen_string_literal: true

Decidim::RestFull::DefinitionRegistry.register_object(:user_extended_data) do
  {
    type: :object,
    title: "User extended data",
    properties: {},
    additionalProperties: true,
    description: <<~README
      Hash of values attached to a user. These values won't be
      displayed to admins or users, consider this as an internal
      data payload.
    README
  }.freeze
end
