# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class AnswerSerializer < ApplicationSerializer
          set_type :answers

          attributes :body

          attribute :question_id do |answer|
            answer.decidim_question_id.to_s
          end

          belongs_to :questionnaire, &:questionnaire
        end
      end
    end
  end
end
