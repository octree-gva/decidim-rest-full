# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:attachment_attached_to) do
  {
    title: "Attachment parent reference",
    type: :object,
    properties: {
      type: { type: :string, description: "Polymorphic type (e.g. Decidim::Proposals::Proposal)" },
      id: { type: :integer }
    },
    required: [:type, :id],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:attachment_attributes) do
  {
    title: "Attachment attributes",
    type: :object,
    properties: {
      title: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop) },
      description: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:translated_prop) },
      weight: { type: :integer },
      attachment_collection_id: { type: :integer, nullable: true },
      file_type: { type: :string, enum: %w(image document link) },
      content_type: { type: :string, nullable: true },
      url: { type: :string, nullable: true, description: "Public URL when file is attached" },
      thumbnail_url: { type: :string, nullable: true },
      attached_to: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:attachment_attached_to) },
      created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
      updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) }
    },
    required: [:title, :attached_to, :created_at],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:attachment) do
  {
    type: :object,
    title: "Attachment",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["attachment"] },
      attributes: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:attachment_attributes) }
    },
    required: [:id, :type, :attributes],
    additionalProperties: false
  }.freeze
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:attachment_direct_upload_response) do
  {
    type: :object,
    properties: {
      signed_id: { type: :string },
      filename: { type: :string },
      content_type: { type: :string },
      byte_size: { type: :integer }
    },
    required: [:signed_id, :filename, :content_type, :byte_size],
    additionalProperties: false
  }
end
