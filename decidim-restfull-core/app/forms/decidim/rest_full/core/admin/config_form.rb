# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      module Admin
        class ConfigForm < Decidim::Form
          include Decidim::Toggle::TabForm
          include Decidim::Toggle::ModuleConfigForm

          self.module_config_name = Decidim::RestFull::Core::ModuleAvailability::MODULE_NAME

          mimic :organization

          attribute :enabled, :boolean, default: true

          Decidim::RestFull::Core::ModuleAvailability::FEATURE_MODULES.each do |feature|
            attribute :"#{feature}_enabled", :boolean, default: true
          end

          def attribute_disabled?(attribute)
            attribute = attribute.to_sym
            return false if attribute == :enabled

            return true unless enabled

            feature = attribute.to_s.delete_suffix("_enabled").to_sym
            return false unless Decidim::RestFull::Core::ModuleAvailability.feature_gems.has_key?(feature)

            !Decidim::RestFull::Core::ModuleAvailability.feature_gem_present?(feature)
          end

          # Disabled inputs are not submitted; omit them so merge keeps prior values.
          def to_h
            super.except(*persist_excluded_keys)
          end

          private

          def persist_excluded_keys
            self.class.attribute_names.map(&:to_sym).reject { |name| [:id, :enabled].include?(name) }.select do |name|
              attribute_disabled?(name)
            end
          end
        end
      end
    end
  end
end
