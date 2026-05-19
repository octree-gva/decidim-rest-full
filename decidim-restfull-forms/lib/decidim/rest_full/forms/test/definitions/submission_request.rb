# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:submission_request) do
  {
    type: :object,
    title: "Submission request (async answer submit)",
    properties: {
      id: { type: :string, format: :uuid },
      type: { type: :string, enum: ["submission_request"] },
      attributes: {
        type: :object,
        properties: {
          status: { type: :string, enum: %w(pending processing completed failed) }
        },
        required: [:status]
      },
      meta: {
        type: :object,
        properties: {
          status: { type: :string }
        }
      },
      links: {
        type: :object,
        properties: {
          self: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link) },
          result: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link) }
        }
      }
    },
    required: [:id, :type, :attributes, :links]
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:submission_request_accepted_response) do
  {
    type: :object,
    title: "Submission request accepted (202)",
    properties: {
      data: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:submission_request) }
    },
    required: [:data]
  }
end
