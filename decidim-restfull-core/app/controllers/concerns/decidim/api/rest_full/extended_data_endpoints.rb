# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      # Shared GET/PUT(/sync) behaviour for resources that include HasExtendedData.
      module ExtendedDataEndpoints
        extend ActiveSupport::Concern

        included do
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action :ensure_resource_extended_data

          before_action only: [:index] do
            authorize! :read_extended_data, extended_data_subject_class
          end

          before_action only: [:update, :update_sync] do
            authorize! :update_extended_data, extended_data_subject_class
          end
        end

        def index
          payload = { data: extended_data_at_path }
          render_json_with_conditional_get(
            payload,
            fingerprint: resource_fingerprint_for(extended_data_resource)
          )
        end

        def update
          enqueue_rest_full_api_job!(extended_data_job_name)
        end

        def update_sync
          render json: (Decidim::RestFull::SyncRunner.call do
            Decidim::RestFull::Core::ApiSystemOperations.new(
              api_execution_context,
              extended_data_operation_params
            ).resource_extended_data_update!
          end)
        end

        private

        def ensure_resource_extended_data
          return if extended_data_resource.extended_data

          extended_data_resource.create_extended_data!
        end

        def extended_data_at_path
          Decidim::RestFull::Core::ExtendedDataAtPath.fetch(extended_data_hash, object_path)
        end

        def object_path
          @object_path ||= params.require(:object_path)
        end

        def extended_data_hash
          extended_data_resource.extended_data_hash
        end

        def extended_data_job_name
          "resource_extended_data#update"
        end

        def extended_data_operation_params
          params.merge(
            resource_type: extended_data_resource.class.name,
            resource_id: extended_data_resource.id
          )
        end

        def rest_full_api_job_payload
          base = super
          base["path"] = (base["path"] || {}).merge(
            "resource_type" => extended_data_resource.class.name,
            "resource_id" => extended_data_resource.id.to_s
          )
          base
        end

        # Override in each controller.
        def extended_data_resource
          raise NotImplementedError
        end

        def extended_data_subject_class
          extended_data_resource.class
        end
      end
    end
  end
end
