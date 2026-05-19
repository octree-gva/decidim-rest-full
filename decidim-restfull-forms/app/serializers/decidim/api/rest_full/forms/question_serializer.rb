# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class QuestionSerializer < ApplicationSerializer
          set_type :questions

          attributes :position, :mandatory, :question_type, :body, :description, :max_choices, :max_characters

          belongs_to :questionnaire, &:questionnaire
        end
      end
    end
  end
end
