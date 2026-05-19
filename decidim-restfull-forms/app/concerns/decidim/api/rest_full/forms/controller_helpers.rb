# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        module ControllerHelpers
          extend ActiveSupport::Concern

          private

          def questionnaire_scope
            @questionnaire_scope ||= Decidim::RestFull::Forms::QuestionnaireScope.new(
              organization: current_organization,
              visibility: participatory_space_visibility
            )
          end

          def locale_resolver
            @locale_resolver ||= Decidim::RestFull::Forms::LocaleResolver.new(
              organization: current_organization,
              user: current_user,
              params:,
              accept_language: request.headers["Accept-Language"]
            )
          end

          def locale_meta
            locale_resolver.meta_hash
          end

          def api_context
            visibility = participatory_space_visibility
            headers = request.headers
            request_params = params
            Decidim::RestFull::ApiExecutionContext.from_controller(self).tap do |ctx|
              ctx.define_singleton_method(:visibility) { visibility }
              ctx.define_singleton_method(:request_headers) { headers }
              ctx.define_singleton_method(:params) { request_params }
            end
          end

          def filter_hash
            fp = params[:filter]
            fp.respond_to?(:to_unsafe_h) ? fp.to_unsafe_h.stringify_keys : {}
          end

          def paginate_relation(relation)
            page = (params[:page].presence || 1).to_i
            per_page = (params[:per_page].presence || 25).to_i
            per_page = 25 if per_page < 1 || per_page > 100
            relation.page(page).per(per_page)
          end

          def questionnaire_show_json(questionnaire)
            projection = Decidim::RestFull::Forms::QuestionnaireJsonFormsBuilder.new(
              questionnaire,
              locale: locale_meta[:locale],
              organization: current_organization,
              host: current_organization.host
            ).build
            Decidim::RestFull::Forms::ResponseBuilder.questionnaire_show(
              questionnaire,
              projection:,
              locale_meta:,
              host: current_organization.host
            )
          end
        end
      end
    end
  end
end
