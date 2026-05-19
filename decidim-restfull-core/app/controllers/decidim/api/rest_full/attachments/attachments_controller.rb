# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Attachments
        class AttachmentsController < ApplicationController
          before_action :ensure_attachments_api_enabled!
          before_action { doorkeeper_authorize! :attachments }
          before_action :authorize_read!, only: [:index, :show]
          before_action :authorize_create!, only: [:create, :direct_upload]
          before_action :authorize_update!, only: [:update]
          before_action :authorize_destroy!, only: [:destroy]

          def index
            items = operations.index_scope
            page = paginate_array(items)
            payload = Core::AttachmentSerializer.new(page, params: serializer_params).serializable_hash
            render json: payload, status: :ok
          end

          def show
            attachment = operations.find!(params.require(:id))
            payload = Core::AttachmentSerializer.new(attachment, params: serializer_params).serializable_hash
            render json: payload, status: :ok
          end

          # Attachments v1 is sync-only (no async job); see integrator/attachments.md
          def create # rubocop:disable Decidim/RestFull/AsyncApiMutation
            attachment = operations.create!
            payload = Core::AttachmentSerializer.new(attachment, params: serializer_params).serializable_hash
            render json: payload, status: :created
          end

          def update # rubocop:disable Decidim/RestFull/AsyncApiMutation
            attachment = operations.find!(params.require(:id))
            operations.update!(attachment)
            payload = Core::AttachmentSerializer.new(attachment.reload, params: serializer_params).serializable_hash
            render json: payload, status: :ok
          end

          def destroy
            attachment = operations.find!(params.require(:id))
            operations.destroy!(attachment)
            head :no_content
          end

          def direct_upload
            render json: operations.direct_upload!, status: :created
          end

          private

          def authorize_read!
            authorize! :read, Decidim::Attachment
          end

          def authorize_create!
            authorize! :create, Decidim::Attachment
          end

          def authorize_update!
            authorize! :update, Decidim::Attachment
          end

          def authorize_destroy!
            authorize! :destroy, Decidim::Attachment
          end

          def ensure_attachments_api_enabled!
            return if Decidim::RestFull::Core::Configuration.enable_attachments_api

            raise Decidim::RestFull::Core::ApiException::NotFound, "Attachments API is disabled"
          end

          def operations
            @operations ||= Decidim::RestFull::Core::AttachmentsOperations.new(api_execution_context, params)
          end

          def serializer_params
            { host: request.host }
          end

          def paginate_array(items)
            page = (params[:page].presence || 1).to_i
            per_page = (params[:per_page].presence || 25).to_i
            per_page = 25 if per_page < 1 || per_page > 100
            Kaminari.paginate_array(items).page(page).per(per_page)
          end
        end
      end
    end
  end
end
