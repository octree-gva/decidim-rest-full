# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:user_extended_data) do
  {
    type: :object,
    title: "User extended data",
    properties: {},
    additionalProperties: true,
    description: <<~README
      Client metadata hash on the current user. Kept out of the Decidim admin UI.
      See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data) (user path: `/me/extended_data`).
    README
  }.freeze
end
