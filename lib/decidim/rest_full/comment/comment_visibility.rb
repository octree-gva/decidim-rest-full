# frozen_string_literal: true

module Decidim
  module RestFull
    module Comment
      # Scopes Comment / CommentVote relations by org and participatory visibility (spaces + components).
      module CommentVisibility
        module_function

        def visible_comments(controller)
          org = controller.send(:current_organization)
          user = controller.send(:act_as)
          cid_sql = Decidim::RestFull::Comment::CommentRansackers.component_id_sql_for_comments_table("decidim_comments_comments")

          vis_components = controller.send(:in_visible_spaces, components_for_organization(org))
          allowed_component_ids = vis_components.ids

          base = Decidim::Comments::Comment.not_hidden.not_deleted
          by_component = if allowed_component_ids.empty?
                           base.none
                         else
                           base.where("#{cid_sql} IN (?)", allowed_component_ids)
                         end

          initiative_scope = initiative_visible_scope(org, user)
          by_initiative = base.where(
            decidim_participatory_space_type: "Decidim::Initiative",
            decidim_participatory_space_id: initiative_scope.select(:id)
          )

          by_component.or(by_initiative)
        end

        def initiative_visible_scope(org, user)
          return Decidim::Initiative.none unless defined?(Decidim::Initiative)

          scope = Decidim::Initiative.where(organization: org)
          return scope if user&.admin?

          scope.published
        end

        # +Decidim::Component+ has no +organization+ column; scope via each participatory space model.
        def components_for_organization(organization)
          parts = Decidim.participatory_space_registry.manifests.filter_map do |manifest|
            klass = manifest.model_class_name.constantize
            next unless klass.column_names.include?("decidim_organization_id")

            space_ids = klass.where(organization:).ids
            next if space_ids.empty?

            Decidim::Component.unscoped.where(
              participatory_space_type: manifest.model_class_name,
              participatory_space_id: space_ids
            )
          end
          return Decidim::Component.none if parts.empty?

          parts.reduce { |a, b| a.or(b) }
        end
      end
    end
  end
end
