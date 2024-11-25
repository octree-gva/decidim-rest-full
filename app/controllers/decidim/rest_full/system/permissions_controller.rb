# frozen_string_literal: true

module Decidim
  module RestFull
    module System
      class PermissionsController < Decidim::System::ApplicationController
        helper Decidim::Admin::AttributesDisplayHelper
        helper Decidim::Core::Engine.routes.url_helpers
        helper_method :destroy_admin_session_path

        def core_engine_routes
          Decidim::Core::Engine.routes.url_helpers
        end

        def create
          @form = form(ApiPermissions).from_params(params)
          api_client = Decidim::RestFull::ApiClient.find(@form.api_client_id)
          api_client.permissions = @form.permissions.map do |perm_string|
            api_client.permissions.build(permission: perm_string)
          end
          api_client.save!
          redirect_to core_engine_routes.edit_system_api_client_path(api_client)
        end
      end
    end
  end
end
