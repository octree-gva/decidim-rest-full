# frozen_string_literal: true

module Decidim
  module RestFull
    module Forms
      # Stable 422 error envelope for forms API.
      class ErrorPayloadBuilder
        def self.from_form(form, locale_meta:)
          errors = form.errors.map do |error|
            question_id = extract_question_id(error.attribute, form)
            {
              title: error.message,
              code: error.type.to_s,
              pointer: pointer_for(error.attribute, question_id),
              question_id:
            }.compact
          end
          { meta: locale_meta, errors: }
        end

        def self.from_message(message, code: "invalid", locale_meta: {})
          { meta: locale_meta, errors: [{ title: message, code: }] }
        end

        def self.extract_question_id(attribute, form)
          match = attribute.to_s.match(/\Aresponse_(\d+)/)
          return match[1] if match

          form.question_id&.to_s if form.is_a?(Decidim::Forms::AnswerForm)
        end

        def self.pointer_for(attribute, question_id)
          return "/data/attributes/answers/#{question_id}" if question_id

          "/data/attributes/#{attribute}"
        end
      end
    end
  end
end
