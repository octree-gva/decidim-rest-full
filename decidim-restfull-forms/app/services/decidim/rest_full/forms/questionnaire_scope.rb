# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      # Tenant-safe questionnaire lookup and filtering for the forms API.
      class QuestionnaireScope
        def initialize(organization:, visibility:)
          @organization = organization
          @visibility = visibility
        end

        def find!(id)
          questionnaire = Decidim::Forms::Questionnaire.includes(
            questions: [:answer_options, :matrix_rows, :display_conditions]
          ).find_by(id:)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Questionnaire not found" unless questionnaire
          raise Decidim::RestFull::Core::ApiException::NotFound, "Questionnaire not found" unless in_organization?(questionnaire)

          questionnaire
        end

        def base_relation
          Decidim::Forms::Questionnaire
            .includes(:questions)
            .where(id: visible_questionnaire_ids)
        end

        def filter(relation, filters)
          ids = filtered_questionnaire_ids(filters)
          return relation.none if ids.empty?

          relation.where(id: ids)
        end

        def organization_for(questionnaire)
          host = questionnaire.questionnaire_for
          if host.respond_to?(:organization)
            host.organization
          elsif host.respond_to?(:component)
            host.component.organization
          end
        end

        def component_for(questionnaire)
          host = questionnaire.questionnaire_for
          host.component if host.respond_to?(:component)
        end

        private

        attr_reader :organization, :visibility

        def in_organization?(questionnaire)
          organization_for(questionnaire)&.id == organization.id
        end

        def visible_questionnaire_ids
          survey_ids = visible_survey_ids
          meeting_ids = visible_meeting_ids
          Decidim::Forms::Questionnaire.where(
            "(questionnaire_for_type = ? AND questionnaire_for_id IN (?)) OR " \
            "(questionnaire_for_type = ? AND questionnaire_for_id IN (?))",
            "Decidim::Surveys::Survey", survey_ids,
            "Decidim::Meetings::Meeting", meeting_ids
          ).pluck(:id)
        end

        def visible_survey_ids
          return [] unless defined?(Decidim::Surveys::Survey)

          component_ids = visible_component_ids("surveys")
          Decidim::Surveys::Survey.where(decidim_component_id: component_ids).pluck(:id)
        end

        def visible_meeting_ids
          return [] unless defined?(Decidim::Meetings::Meeting)

          component_ids = visible_component_ids("meetings")
          Decidim::Meetings::Meeting.where(decidim_component_id: component_ids).pluck(:id)
        end

        def visible_component_ids(manifest_name)
          components = Decidim::Component.where(manifest_name:)
          return components.pluck(:id) unless visibility

          visibility.in_visible_spaces(components).pluck(:id)
        end

        def filtered_questionnaire_ids(filters)
          ids = visible_questionnaire_ids
          if filters["component_id"].present?
            cids = Array(filters["component_id"]).map(&:to_i)
            ids &= questionnaire_ids_for_component_ids(cids)
          end
          if filters["participatory_space_id"].present?
            space_ids = Array(filters["participatory_space_id"]).map(&:to_i)
            ids &= questionnaire_ids_for_space_ids(space_ids)
          end
          if filters["questionnaire_id"].present?
            qids = Array(filters["questionnaire_id"]).map(&:to_i)
            ids &= qids
          end
          ids
        end

        def questionnaire_ids_for_component_ids(component_ids)
          survey_q = survey_questionnaire_ids_for_components(component_ids)
          meeting_q = meeting_questionnaire_ids_for_components(component_ids)
          survey_q + meeting_q
        end

        def questionnaire_ids_for_space_ids(space_ids)
          component_ids = Decidim::Component.where(participatory_space_id: space_ids).pluck(:id)
          questionnaire_ids_for_component_ids(component_ids)
        end

        def survey_questionnaire_ids_for_components(component_ids)
          return [] unless defined?(Decidim::Surveys::Survey)

          Decidim::Forms::Questionnaire
            .joins("INNER JOIN decidim_surveys_surveys ON decidim_surveys_surveys.id = decidim_forms_questionnaires.questionnaire_for_id " \
                   "AND decidim_forms_questionnaires.questionnaire_for_type = 'Decidim::Surveys::Survey'")
            .where(decidim_surveys_surveys: { decidim_component_id: component_ids })
            .pluck(:id)
        end

        def meeting_questionnaire_ids_for_components(component_ids)
          return [] unless defined?(Decidim::Meetings::Meeting)

          Decidim::Forms::Questionnaire
            .joins("INNER JOIN decidim_meetings_meetings ON decidim_meetings_meetings.id = decidim_forms_questionnaires.questionnaire_for_id " \
                   "AND decidim_forms_questionnaires.questionnaire_for_type = 'Decidim::Meetings::Meeting'")
            .where(decidim_meetings_meetings: { decidim_component_id: component_ids })
            .pluck(:id)
        end
      end
    end
  end
end
