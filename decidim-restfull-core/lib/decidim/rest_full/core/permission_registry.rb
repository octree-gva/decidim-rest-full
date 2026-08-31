# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Registry for fine-grained API permissions (abilities) attached to OAuth
      # clients. Used by the System UI to render checkboxes per scope/group, and
      # extensible by external modules.
      module PermissionRegistry
        Entry = Struct.new(:key, :scope, :group, :event, keyword_init: true)

        class << self
          def register(scope, key, group: nil, event: false)
            key = key.to_s
            scope = scope.to_s
            group = group&.to_s
            return registry[key] if registry.has_key?(key)

            registry[key] = Entry.new(key:, scope:, group:, event:)
          end

          def all
            registry.values
          end

          def by_scope(scope)
            scope = scope.to_s
            registry.values.select { |entry| entry.scope == scope }
          end

          def by_scope_and_group(scope, group)
            scope = scope.to_s
            group = group.to_s
            registry.values.select { |entry| entry.scope == scope && entry.group == group }
          end

          def events_for(scope)
            scope = scope.to_s
            registry.values.select { |entry| entry.scope == scope && entry.event }
          end

          # Scopes with registered abilities rendered by the System API client UI
          # (core + feature gems list scopes explicitly in +_edit_info_tab+).
          BUILTIN_UI_SCOPES = %w[
            system public blogs debates budgets surveys accountability proposals meetings oauth
          ].freeze

          def extension_ui_scopes
            all.map(&:scope).uniq - BUILTIN_UI_SCOPES
          end

          def extension_ui_groups(scope)
            by_scope(scope).reject(&:event).filter_map(&:group).uniq
          end

          private

          def registry
            @registry ||= {}
          end
        end
      end
    end
  end
end
