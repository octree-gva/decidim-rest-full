# frozen_string_literal: true

module Api
  module Definitions
    SPACE_MANIFEST = {
      title: "Space Manifest",
      type: :string,
      enum: Decidim.participatory_space_registry.manifests.map(&:name)
    }.freeze
    COMPONENT_MANIFEST = {
      title: "Component Manifest",
      type: :string,
      enum: Decidim.component_registry.manifests.map(&:name).reject { |manifest_name| manifest_name == :dummy }
    }.freeze
  end
end
