# frozen_string_literal: true

module Api
  module Definitions
    COMPONENT_TYPE = {
      type: :string,
      enum: Decidim.component_registry.manifests.map { |manifest| "#{manifest.name.to_s.singularize}_component" }.reject { |manifest_name| manifest_name == "dummy_component" }
    }.freeze
  end
end
