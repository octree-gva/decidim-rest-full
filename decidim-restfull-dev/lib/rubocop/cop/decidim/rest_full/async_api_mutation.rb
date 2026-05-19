# frozen_string_literal: true

module RuboCop
  module Cop
    module Decidim
      module RestFull
        # Ensures mutating controller actions enqueue async API jobs unless explicitly sync.
        class AsyncApiMutation < ::RuboCop::Cop::Base
          MSG = "Mutating actions should call `enqueue_rest_full_api_job!` or `enqueue_forms_answer_job!`, " \
                "or use an action name ending in `_sync` (see website/docs/dev/add-endpoint/async.md)."

          MUTATION_NAMES = [:create, :update, :destroy, :publish, :vote].freeze
          ASYNC_MARKERS = %w(
            enqueue_rest_full_api_job!
            enqueue_forms_answer_job!
          ).freeze
          SYNC_MARKERS = %w(
            SyncRunner.call
            head :no_content
            head :method_not_allowed
          ).freeze

          def on_def(node)
            name = node.method_name
            return unless mutation_action?(name)
            return if name.to_s.end_with?("_sync")

            body = node.body&.source
            return if body.nil?
            return if async_or_inline_sync?(body)

            add_offense(node.loc.name, message: MSG)
          end

          private

          def mutation_action?(name)
            MUTATION_NAMES.include?(name)
          end

          def async_or_inline_sync?(body)
            ASYNC_MARKERS.any? { |m| body.include?(m) } ||
              SYNC_MARKERS.any? { |m| body.include?(m) }
          end
        end
      end
    end
  end
end
