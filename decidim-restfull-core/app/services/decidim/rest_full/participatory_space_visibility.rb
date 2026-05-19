# frozen_string_literal: true

module Decidim
  module RestFull
    # Shared participatory-space / component visibility for API actors and services.
    # Used by {Decidim::Api::RestFull::ApplicationController}, proposal operations, etc.
    class ParticipatorySpaceVisibility
      def initialize(organization:, act_as:)
        @organization = organization
        @act_as = act_as
      end

      def visible_spaces
        @visible_spaces ||= begin
          spaces = Decidim.participatory_space_registry.manifests.map do |space|
            model = space.model_class_name
            next unless Object.const_defined?(model)

            klass = model.constantize
            query = visible_scope_for(klass, act_as)
            {
              participatory_space_type: model,
              participatory_space_id: query.ids
            }
          end
          spaces.compact.reject { |s| s[:participatory_space_id].empty? }
        end
      end

      def in_visible_spaces(context = Decidim::Component.all)
        vs = visible_spaces
        if vs.size.positive?
          first = vs.first
          query = context.where(**first)
          vs[1..].each { |s| query = query.or(context.where(**s)) }
          query
        else
          context.where("1=0")
        end
      end

      def visible_scope_for(klass, user)
        base = klass.where(organization:)
        if base.respond_to?(:visible_for)
          base.visible_for(user)
        elsif base.respond_to?(:published)
          base.published
        else
          base
        end
      end

      def space_class_from_name(manifest_name)
        Decidim.participatory_space_registry.manifests.find do |manifest|
          manifest.name == :"#{manifest_name}"
        end.model_class_name
      end

      private

      attr_reader :organization, :act_as
    end
  end
end
