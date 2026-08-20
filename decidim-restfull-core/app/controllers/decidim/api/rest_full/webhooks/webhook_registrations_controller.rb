# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Webhooks
        class WebhookRegistrationsController < ApplicationController
          before_action { doorkeeper_authorize! :webhooks }
          before_action :authorize_read!, only: [:index, :show]
          before_action :authorize_create!, only: [:create]
          before_action :authorize_update!, only: [:update]
          before_action :authorize_destroy!, only: [:destroy]

          def index
            items = base_scope.order(created_at: :desc)
            page = paginate_collection(items)
            payload = Core::WebhookRegistrationSerializer.new(page, params: serializer_params).serializable_hash
            render json: payload, status: :ok
          end

          def show
            registration = find_owned!
            payload = Core::WebhookRegistrationSerializer.new(registration, params: serializer_params).serializable_hash
            render json: payload, status: :ok
          end

          def create # rubocop:disable Decidim/RestFull/AsyncApiMutation
            form = build_form
            raise Decidim::RestFull::Core::ApiException::BadRequest, form.errors.full_messages.join(", ") unless form.valid?

            registration = Decidim::RestFull::Core::WebhookRegistration.create!(
              api_client: current_api_client,
              url: form.url,
              subscriptions: form.subscriptions
            )
            payload = Core::WebhookRegistrationSerializer.new(
              registration,
              params: serializer_params.merge(include_signing_secret: true)
            ).serializable_hash
            render json: payload, status: :created
          end

          def update # rubocop:disable Decidim/RestFull/AsyncApiMutation
            registration = find_owned!
            form = build_form
            raise Decidim::RestFull::Core::ApiException::BadRequest, form.errors.full_messages.join(", ") unless form.valid?

            registration.update!(url: form.url, subscriptions: form.subscriptions)
            payload = Core::WebhookRegistrationSerializer.new(registration.reload, params: serializer_params).serializable_hash
            render json: payload, status: :ok
          end

          def destroy
            find_owned!.destroy!
            head :no_content
          end

          private

          def authorize_read!
            authorize! :read, Decidim::RestFull::Core::WebhookRegistration
          end

          def authorize_create!
            authorize! :create, Decidim::RestFull::Core::WebhookRegistration
          end

          def authorize_update!
            authorize! :update, Decidim::RestFull::Core::WebhookRegistration
          end

          def authorize_destroy!
            authorize! :destroy, Decidim::RestFull::Core::WebhookRegistration
          end

          def current_api_client
            doorkeeper_token.application
          end

          def base_scope
            Decidim::RestFull::Core::WebhookRegistration.where(api_client_id: current_api_client.id)
          end

          def find_owned!
            registration = base_scope.find_by(id: params.require(:id))
            raise Decidim::RestFull::Core::ApiException::NotFound, "Webhook registration not found" unless registration

            registration
          end

          def build_form
            attrs = params.require(:data).require(:attributes).permit(:url, subscriptions: []).to_h
            Decidim::RestFull::Core::WebhookRegistrationForm
              .from_params(attrs)
              .with_context(api_client: current_api_client)
          end

          def serializer_params
            { host: request.host }
          end

          def paginate_collection(items)
            page = (params[:page].presence || 1).to_i
            per_page = (params[:per_page].presence || 25).to_i
            per_page = 25 if per_page < 1 || per_page > 100
            items.page(page).per(per_page)
          end
        end
      end
    end
  end
end
