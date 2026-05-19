# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Roles
        class RolesController < ApplicationController
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing
          before_action :doorkeeper_authorize_roles!
          before_action :authorize_read!, only: [:index, :show]
          before_action :authorize_create!, only: [:create, :create_sync]
          before_action :authorize_destroy!, only: [:destroy, :destroy_sync]

          def index
            roles = filtered_roles
            paginated = paginate_array(roles)
            payload = Core::RoleSerializer.new(paginated, params: serializer_params).serializable_hash
            render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for(paginated))
          end

          def show
            role = aggregator.find_by(id: params.require(:id))
            raise Decidim::RestFull::Core::ApiException::NotFound, "Role Not Found" unless role

            payload = Core::RoleSerializer.new(role, params: serializer_params).serializable_hash
            render_json_with_conditional_get(payload, fingerprint: collection_fingerprint_for([role]))
          end

          def create
            enqueue_rest_full_api_job!("roles#create")
          end

          def create_sync
            json = Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Core::ApiSystemOperations.new(api_execution_context, params).roles_create!
            end
            render json:, status: :created
          rescue ArgumentError => e
            render json: { errors: [{ title: e.message }] }, status: :unprocessable_entity
          end

          def destroy
            enqueue_rest_full_api_job!("roles#destroy")
          end

          def destroy_sync
            Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Core::ApiSystemOperations.new(api_execution_context, params).roles_destroy!
            end
            head :no_content
          end

          private

          def doorkeeper_authorize_roles!
            doorkeeper_authorize! :roles
          end

          def authorize_read!
            authorize! :read, :role
          end

          def authorize_create!
            authorize! :create, :role
          end

          def authorize_destroy!
            authorize! :destroy, :role
          end

          def role_params_from_body
            data = params.require(:data).to_unsafe_h
            attrs = data["attributes"] || data[:attributes] || {}
            {
              resource_type: attrs["resource_type"] || attrs[:resource_type],
              resource_id: attrs["resource_id"] || attrs[:resource_id],
              user_id: attrs["user_id"] || attrs[:user_id],
              type: attrs["type"] || attrs[:type]
            }.compact
          end

          def aggregator
            @aggregator ||= Decidim::RestFull::Core::Roles::RolesAggregator.new(current_organization)
          end

          def writer
            @writer ||= Decidim::RestFull::Core::Roles::RolesWriter.new(current_organization)
          end

          def filtered_roles
            list = aggregator.call
            filter = filter_hash
            role_filter_predicates(filter).each { |predicate| list = list.select(&predicate) }
            list
          end

          def filter_hash
            fp = params[:filter]
            fp.respond_to?(:to_unsafe_h) ? fp.to_unsafe_h : {}
          end

          ROLE_FILTERS = [
            ["user_id_eq", ->(r, v) { r.user_id == v.to_i }],
            ["resource_id_eq", ->(r, v) { r.resource_id == v.to_i }],
            ["resource_type_eq", ->(r, v) { r.resource_type == v }],
            ["type_eq", ->(r, v) { r.type == v }]
          ].freeze

          def role_filter_predicates(filter)
            ROLE_FILTERS.filter_map do |key, block|
              value = filter[key]
              value.present? ? ->(r) { block.call(r, value) } : nil
            end
          end

          def paginate_array(roles)
            page = (params[:page].presence || 1).to_i
            per_page = (params[:per_page].presence || 25).to_i
            per_page = 25 if per_page < 1 || per_page > 100
            Kaminari.paginate_array(roles).page(page).per(per_page)
          end

          def serializer_params
            { host: current_organization.host }
          end
        end
      end
    end
  end
end
