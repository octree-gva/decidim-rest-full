# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class QuestionnaireSerializer < ApplicationSerializer
          set_type :questionnaires

          attribute :title do |questionnaire, params|
            translate_field(questionnaire.title, params[:locale])
          end

          attribute :description do |questionnaire, params|
            translate_field(questionnaire.description, params[:locale])
          end

          attribute :schema, if: proc { |_, params| params[:projection].present? } do |_, params|
            params[:projection][:schema]
          end

          attribute :ui, if: proc { |_, params| params[:projection].present? } do |_, params|
            params[:projection][:ui]
          end

          attribute :updated_at do |questionnaire|
            questionnaire.updated_at&.iso8601
          end

          meta do |_questionnaire, params|
            base = params[:locale_meta] || {}
            if params[:projection].present?
              base.merge(submission: params[:projection][:meta])
            else
              base
            end
          end

          link :self do |questionnaire, params|
            prefix = api_prefix(params[:host])
            {
              href: "#{prefix}/questionnaires/#{questionnaire.id}",
              rel: "self",
              meta: { action_method: "GET" }
            }
          end

          link :submit do |questionnaire, params|
            {
              href: "#{api_prefix(params[:host])}/answers",
              rel: "submit",
              meta: { action_method: "POST", questionnaire_id: questionnaire.id.to_s }
            }
          end

          link :submit_sync do |_, params|
            {
              href: "#{api_prefix(params[:host])}/answers/sync",
              rel: "submit_sync",
              meta: { action_method: "POST" }
            }
          end

          link :questions do |questionnaire, params|
            {
              href: "#{api_prefix(params[:host])}/questions?filter[questionnaire_id]=#{questionnaire.id}",
              rel: "questions",
              meta: { action_method: "GET" }
            }
          end
        end
      end
    end
  end
end
