# frozen_string_literal: true

require "fast_jsonapi/helpers"

module Decidim
  module RestFull
    module Core
      # Applies +rest_enhancement+ registrations to JSON:API serializers at boot / +to_prepare+.
      class SerializerAdditionsRegistry
        class << self
          def reset!
            @registrations = []
            @relationship_index = Hash.new { |h, k| h[k] = [] }
            @applied_guards = Set.new
          end

          def register(registration)
            reset_if_needed

            existing = @relationship_index[registration.serializer_name]
            overlap = existing & registration.relationship_names
            if overlap.any?
              raise ArgumentError,
                    "rest_enhancement relationship conflict on #{registration.serializer_name} " \
                    "(extensions #{registration.extension_name} vs existing keys #{overlap.inspect})"
            end

            existing.concat(registration.relationship_names)
            @registrations << registration
          end

          def apply!
            reset_if_needed
            grouped = @registrations.group_by(&:serializer_name)
            grouped.each do |serializer_name, regs|
              klass = serializer_name.safe_constantize
              next unless klass

              guard_key = [serializer_name, klass.object_id]
              next if @applied_guards.include?(guard_key)

              apply_to_class!(klass, regs)
              @applied_guards.add(guard_key)
            end
          end

          private

          def reset_if_needed
            @registrations ||= []
            @relationship_index ||= Hash.new { |h, k| h[k] = [] }
            @applied_guards ||= Set.new
          end

          def apply_to_class!(klass, registrations)
            original_meta = klass.meta_to_serialize
            install_relationship_and_link_installers!(klass, registrations)
            install_merged_meta!(klass, registrations, original_meta:)
          end

          def install_relationship_and_link_installers!(klass, registrations)
            registrations.each do |reg|
              reg.relationship_installers.each { |installer| klass.class_eval(&installer) }
              reg.link_installers.each { |installer| klass.class_eval(&installer) }
            end
          end

          def install_merged_meta!(klass, registrations, original_meta:)
            meta_frags = registrations.flat_map(&:meta_fragments)
            return if meta_frags.empty?

            klass.meta do |record, params|
              merged_meta_hash(record, params, original_meta:, meta_frags:, klass_name: klass.name)
            end
          end

          def merged_meta_hash(record, params, original_meta:, meta_frags:, klass_name:)
            h = {}
            if original_meta.present?
              base = FastJsonapi.call_proc(original_meta, record, params)
              merge_meta!(h, base, context: "#{klass_name} base meta") if base.is_a?(Hash)
            end
            meta_frags.each_with_index do |frag, idx|
              piece = frag.call(record, params)
              merge_meta!(h, piece, context: "#{klass_name} rest_enhancement meta[#{idx}]") if piece.is_a?(Hash)
            end
            h
          end

          def merge_meta!(into, piece, context:)
            piece.each_key do |k|
              raise ArgumentError, "Duplicate meta key #{k.inspect} while merging #{context}" if into.has_key?(k)
            end
            into.merge!(piece)
          end
        end
      end
    end
  end
end
