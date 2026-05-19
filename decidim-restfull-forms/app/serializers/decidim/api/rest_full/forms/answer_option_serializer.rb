# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Forms
        class AnswerOptionSerializer < ApplicationSerializer
          set_type :answer_options

          attribute :body

          belongs_to :question, &:question
        end
      end
    end
  end
end
