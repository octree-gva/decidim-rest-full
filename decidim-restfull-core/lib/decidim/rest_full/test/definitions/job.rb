# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_object(:rest_full_hypermedia_link) do
  {
    title: "Hypermedia link",
    type: :object,
    properties: {
      href: { type: :string, description: "Target URL" },
      title: { type: :string },
      rel: { type: :string },
      meta: {
        type: :object,
        properties: {
          action_method: { type: :string, description: "HTTP method for the link target" }
        },
        additionalProperties: true
      }
    },
    required: [:href, :rel],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:rest_full_api_job_links) do
  {
    title: "API job hypermedia controls",
    type: :object,
    properties: {
      self: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_hypermedia_link) }
    },
    required: [:self],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:rest_full_api_job_summary) do
  {
    title: "API job summary",
    type: :object,
    properties: {
      id: {
        type: :string,
        format: :uuid,
        description: "Job identifier; use with GET /jobs/{id}"
      },
      status: {
        type: :string,
        enum: %w(pending processing completed failed),
        description: "Lifecycle state"
      },
      command_key: { type: :string, description: "Async handler key registered by the REST extension" },
      created_at: { type: :string, format: :"date-time" },
      updated_at: { type: :string, format: :"date-time" },
      links: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_links) }
    },
    required: [:id, :status, :command_key, :created_at, :updated_at, :links],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:rest_full_api_job_detail) do
  {
    title: "API job",
    type: :object,
    properties: {
      id: {
        type: :string,
        format: :uuid,
        description: "Job identifier from the HTTP 202 body"
      },
      status: { type: :string, enum: %w(pending processing completed failed) },
      command_key: { type: :string },
      created_at: { type: :string, format: :"date-time" },
      updated_at: { type: :string, format: :"date-time" },
      error_class: { type: :string, nullable: true },
      error_message: { type: :string, nullable: true },
      data: {
        nullable: true,
        description: "Success payload embedded from the worker (shape depends on command_key)"
      },
      return_value: {
        nullable: true,
        description: "Alias retained for backwards compatibility when present"
      },
      links: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_links) }
    },
    required: [:id, :status, :command_key, :created_at, :updated_at, :links],
    additionalProperties: true
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:rest_full_api_jobs_index_response) do
  {
    title: "API jobs index payload",
    type: :object,
    properties: {
      data: {
        type: :array,
        items: {
          "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_summary)
        }
      },
      meta: {
        type: :object,
        properties: {
          page: { type: :integer },
          per_page: { type: :integer }
        },
        required: [:page, :per_page],
        additionalProperties: false
      }
    },
    required: [:data, :meta],
    additionalProperties: false
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:rest_full_api_job_accepted) do
  {
    title: "HTTP 202 async job envelope",
    type: :object,
    properties: {
      job_id: { type: :string, format: :uuid },
      status: { type: :string, enum: %w(pending) },
      data: { nullable: true },
      return_value: { nullable: true },
      poll_url: {
        type: :string,
        description: "Absolute URL for GET /jobs/{job_id}; duplicate of links.self.href for flat JSON clients"
      },
      links: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:rest_full_api_job_links) }
    },
    required: [:job_id, :status, :data, :return_value, :poll_url, :links],
    additionalProperties: false
  }
end
