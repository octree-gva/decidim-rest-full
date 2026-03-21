# frozen_string_literal: true

module Decidim
  module RestFull
    module System
      class WebhookRegistrationsController < Decidim::System::ApplicationController
        helper Decidim::Admin::AttributesDisplayHelper
        helper Decidim::Core::Engine.routes.url_helpers
        helper_method :destroy_admin_session_path

        def core_engine_routes
          Decidim::Core::Engine.routes.url_helpers
        end

        def create
          api_client = Decidim::RestFull::Core::ApiClient.find(webhook_registration_params[:api_client_id])
          @form = form(WebhookRegistrationForm).from_params(
            webhook_registration_params,
            api_client:
          )

          if @form.valid?
            Decidim::RestFull::Core::WebhookRegistration.create!(
              api_client:,
              url: @form.url,
              subscriptions: @form.subscriptions
            )
            flash[:notice] = I18n.t("create.success", scope: "decidim.rest_full.system.webhook_registrations", default: "Webhook registration created successfully")
          else
            flash[:alert] = @form.errors.full_messages.join(", ")
          end
          redirect_to core_engine_routes.edit_system_api_client_path(api_client)
        end

        def destroy
          webhook_registration = Decidim::RestFull::Core::WebhookRegistration.find(params[:id])
          webhook_registration.destroy
          redirect_to core_engine_routes.edit_system_api_client_path(webhook_registration.api_client)
        end

        private

        def webhook_registration_params
          params.require(:webhook_registration_form).permit!
        end
      end
    end
  end
end
