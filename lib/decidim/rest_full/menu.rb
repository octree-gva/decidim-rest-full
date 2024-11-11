# frozen_string_literal: true

module Decidim
  module RestFull
    class Menu
      def self.register_system_menu!
        Decidim.menu :system_menu do |menu|
          menu.add_item :api_clients,
                        I18n.t("menu.api_clients", scope: "decidim.rest_full.admin"),
                        Decidim::RestFull.decidim_rest_full.system_api_clients_path,
                        position: 4
        end
      end
    end
  end
end
