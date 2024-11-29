# frozen_string_literal: true

module Decidim
  module RestFull
    module System
      class ApiClientsController < Decidim::System::ApplicationController
        helper Decidim::Admin::AttributesDisplayHelper
        helper Decidim::Core::Engine.routes.url_helpers
        helper_method :destroy_admin_session_path
        def core_engine_routes
          Decidim::Core::Engine.routes.url_helpers
        end

        def destroy_admin_session_path
          Decidim::System::Engine.routes.url_helpers.destroy_admin_session_path
        end

        def index
          @api_clients = collection.page(params[:page]).per(15)
        end

        def show
          @api_client = collection.find(params[:id])
          @form = form(ApiClientForm).from_model(@api_client)
        end

        def new
          @form = form(ApiClientForm).instance
        end

        def edit
          @api_client = collection.find(params[:id])
          @form = form(ApiClientForm).from_model(@api_client)
          @perm_form = form(ApiPermissions).from_model(@api_client)
        end

        def create
          @form = form(ApiClientForm).from_params(params)

          CreateApiClient.call(@form) do
            on(:ok) do |api_client|
              flash[:notice] = I18n.t("create.success", scope: "decidim.rest_full.system.api_clients")
              redirect_to core_engine_routes.edit_system_api_client_path(api_client)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("create.error", scope: "decidim.rest_full.system.api_clients")
              render :new
            end
          end
        end

        def destroy
          @api_client = collection.find(params[:id])
          @api_client.destroy
          redirect_to core_engine_routes.system_api_clients_path, flash: { success: "Client Revoked" }
        end

        private

        def collection
          @collection = Decidim::RestFull::ApiClient.includes([:organization])
        end
      end
    end
  end
end
