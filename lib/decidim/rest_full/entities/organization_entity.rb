# frozen_string_literal: true

module Decidim
  module RestFull
    module Entities
      class OrganizationEntity < Grape::Entity
        format_with(:iso_timestamp, &:iso8601)
        root "organizations", "organization"

        expose :id, documentation: { type: "Integer", desc: "Organization ID", required: true }
        expose :name, documentation: { type: "Decidim::RestFull::Entities::TranslatedEntity", desc: "Name of the organization - Translated" } do |org, options|
          Entities::TranslatedEntity.represent(org.name.with_indifferent_access, options.merge(only: options[:locales]))
        end

        expose :host, documentation: { type: "String", desc: "Primary host for the organization." }
        expose :secondary_hosts, documentation: { type: "String", desc: "Secondary host for the organization." }

        with_options(format_with: :iso_timestamp) do
          expose :created_at
          expose :updated_at
        end

        expose :meta, with: Entities::MetaEntity do |_org, options|
          {
            populated: options[:only],
            locales: options[:locales]
          }
        end
      end
    end
  end
end
