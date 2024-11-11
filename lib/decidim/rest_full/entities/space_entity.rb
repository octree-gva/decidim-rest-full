# frozen_string_literal: true

module Decidim
    module RestFull
      module Entities
        class SpaceEntity < Grape::Entity
          format_with(:iso_timestamp, &:iso8601)
          root "spaces", "space"
  
          expose :id, documentation: { type: "Integer", desc: "Space ID", required: true }
          expose :manifest, documentation: { type: "String", desc: "Space type", required: true }
          expose :title, documentation: { type: "Decidim::RestFull::Entities::TranslatedEntity", desc: "Title of the space - Translated" } do |space, options|
            Entities::TranslatedEntity.represent(space.title.with_indifferent_access, options.merge(only: options[:locales]))
          end
          expose :subtitle, documentation: { type: "Decidim::RestFull::Entities::TranslatedEntity", desc: "Subtitle of the space - Translated" } do |space, options|
            Entities::TranslatedEntity.represent(space.subtitle.with_indifferent_access, options.merge(only: options[:locales]))
          end
          expose :description, documentation: { type: "Decidim::RestFull::Entities::TranslatedEntity", desc: "Description of the space - Translated" } do |space, options|
            Entities::TranslatedEntity.represent(space.description.with_indifferent_access, options.merge(only: options[:locales]))
          end
          expose :short_description, documentation: { type: "Decidim::RestFull::Entities::TranslatedEntity", desc: "Short Description of the space - Translated" } do |space, options|
            Entities::TranslatedEntity.represent(space.short_description.with_indifferent_access, options.merge(only: options[:locales]))
          end
  
  
          with_options(format_with: :iso_timestamp) do
            expose :created_at
            expose :updated_at
            expose :published_at
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
  