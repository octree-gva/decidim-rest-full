# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        # Webhook envelope for participatory process / space lifecycle events.
        # SpaceSerializer expects SQL-selected +manifest_name+ / +class_name+ (see SpacesController).
        class SpaceWebhookSerializer < WebhookSerializer
          def initialize(resource, event_name:, organization:, timestamp: nil, step: nil)
            super(resource, event_name:, organization:, timestamp:)
            @step = step || resource.try(:active_step)
          end

          def self.find_example_resource(organization, event_name:) # rubocop:disable Lint/UnusedMethodArgument
            Decidim::ParticipatoryProcess.unscoped.where(decidim_organization_id: organization.id).order(:id).last
          end

          protected

          def resource_serializable_hash
            hash = SpaceSerializer.new(space_for_serialization, params: serializer_params).serializable_hash
            merge_active_step_meta!(hash)
            hash
          end

          private

          attr_reader :step

          def space_for_serialization
            model = resource.class
            table = model.table_name
            model.select(
              "#{table}.*",
              "'#{resource.manifest.name}' AS manifest_name",
              "'#{model.name}' AS class_name"
            ).find(resource.id)
          end

          def merge_active_step_meta!(hash)
            return unless step

            data = hash[:data] || hash["data"]
            return unless data

            meta = (data[:meta] || data["meta"] || {}).dup
            meta["active_step_id"] = step.id.to_s
            meta["active_step_position"] = step.position
            meta["active_step_title"] = translated_step_title
            data[:meta] = meta
          end

          def translated_step_title
            title = step.title
            return title unless title.is_a?(Hash)

            title[I18n.locale.to_s] || title["en"] || title.values.first
          end
        end
      end
    end
  end
end
