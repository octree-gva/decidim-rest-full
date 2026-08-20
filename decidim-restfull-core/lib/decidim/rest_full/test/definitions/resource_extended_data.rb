# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:resource_extended_data) do
  {
    type: :object,
    title: "Resource extended data",
    properties: {
      data: {
        description: "Value at the requested object_path (`.` for the full hash)."
      }
    },
    required: [:data],
    additionalProperties: false,
    description: <<~README
      Client metadata hash on a Decidim resource (`HasExtendedData`).
      Kept out of the Decidim admin UI.
      See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).
    README
  }.freeze
end
