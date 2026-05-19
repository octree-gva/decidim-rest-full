# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class QuestionnaireResponseSerializer < ApplicationSerializer
          set_type :questionnaire_response

          set_id(&:id)

          attribute :answers, &:answers_map

          attribute :client_ip, &:ip_hash

          meta do |bundle, params|
            locale_meta = params[:locale_meta] || {}
            locale_meta.merge(
              user: bundle.user ? { id: bundle.user.id.to_s, type: "user" } : nil,
              created_at: bundle.created_at&.iso8601
            )
          end

          link :self do |bundle, params|
            {
              href: "#{api_prefix(params[:host])}/questionnaire_responses/#{bundle.id}",
              rel: "self",
              meta: { action_method: "GET" }
            }
          end

          belongs_to :questionnaire, record_type: :questionnaires, &:questionnaire
        end
      end
    end
  end
end
