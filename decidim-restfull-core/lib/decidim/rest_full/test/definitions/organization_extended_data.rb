# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:organization_extended_data) do
  {
    type: :object,
    title: "Organization extended data",
    properties: {
      data: {
        description: "Value at object_path (object, array, string, number, boolean, or null)."
      }
    },
    required: [:data],
    additionalProperties: true,
    description: <<~README
      Client metadata hash on an organization (`HasExtendedData`).
      See [Extended data](#{Decidim::RestFull.config.docs_url}/integrator/extended-data).
    README
  }.freeze
end
