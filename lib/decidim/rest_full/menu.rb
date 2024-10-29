# frozen_string_literal: true

module Decidim
  module RestFull
    class Menu
      def self.register_admin_menu_settings!
        Decidim.menu :admin_rest_full_menu do |menu|
          menu.add_item :configuration,
                        I18n.t("menu.rest_full", scope: "decidim.rest_full.admin"),
                        Decidim::RestFull.decidim_admin_rest_full.config_index_path,
                        position: 1

          menu.add_item :collectives,
                        I18n.t("menu.collectives", scope: "decidim.rest_full.admin"),
                        Decidim::RestFull.decidim_admin_rest_full.collectives_path,
                        position: 1.1
        end
      end

      def self.register_admin_menu_modules!
        Decidim.menu :admin_settings_menu do |menu|
          menu.add_item :rest_full,
                        I18n.t("menu.rest_full", scope: "decidim.rest_full.admin"),
                        Decidim::RestFull.decidim_admin_rest_full.config_index_path,
                        icon_name: "bubble-chart-line",
                        position: 10,
                        active: is_active_link?(Decidim::RestFull.decidim_admin_rest_full.config_index_path),
                        if: allowed_to?(:read, :area)
        end
      end
    end
  end
end
