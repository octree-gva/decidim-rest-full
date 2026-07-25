# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class SettingsTab
        def self.register!
          name = ModuleAvailability::MODULE_NAME
          Decidim::Toggle.settings_tabs :organization_settings do |tabs|
            tabs.add_tab :decidim_restfull,
                         I18n.t("decidim_toggle.system.#{name}.tab"),
                         form: Decidim::RestFull::Core::Admin::ConfigForm,
                         command: Decidim::Toggle::UpdateModuleConfigCommand,
                         module_name: name,
                         form_layout_partial: "decidim/rest_full/core/admin/organization_settings_tab",
                         position: 30
          end
        end
      end
    end
  end
end
