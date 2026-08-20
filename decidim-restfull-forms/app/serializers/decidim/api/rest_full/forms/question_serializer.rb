# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class QuestionSerializer < ApplicationSerializer
          set_type :questions

          attributes :position, :mandatory, :body, :description, :max_choices, :max_characters

          attribute :question_type do |question|
            Decidim::RestFull::Forms::Decidim032Compat.api_question_type(question.question_type)
          end

          belongs_to :questionnaire, &:questionnaire
        end
      end
    end
  end
end
