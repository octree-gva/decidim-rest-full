# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Meetings
        class MeetingsController < Decidim::Api::RestFull::Core::ResourcesController
          before_action { doorkeeper_authorize! :meetings }
          before_action { ability.authorize! :read, ::Decidim::Meetings::Meeting }

          def index
            authorize_extended_data_filter!(::Decidim::Meetings::Meeting)
            query = collection.ransack(params[:filter])
            results = query.result
            scoped = ordered(results).includes(:component)
            page = paginate(scoped)
            payload = Decidim::Api::RestFull::Meetings::MeetingSerializer.new(
              page,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                client_id:,
                act_as:,
                includes_extended: can?(:read_extended_data, ::Decidim::Meetings::Meeting)
              }
            ).serializable_hash
            fp = Decidim::RestFull::Core::HttpCache::CollectionFingerprint.for_request(
              self,
              relation: scoped.except(:order, :reorder)
            )
            render_json_with_conditional_get(payload, fingerprint: fp)
          end

          def show
            @resource = find_meeting!
            payload = Decidim::Api::RestFull::Meetings::MeetingSerializer.new(
              @resource,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                client_id:,
                act_as:,
                includes_extended: can?(:read_extended_data, ::Decidim::Meetings::Meeting)
              }
            ).serializable_hash
            render_json_with_conditional_get(
              payload,
              fingerprint: Decidim::RestFull::Core::HttpCache::ResourceShowFingerprint.for_request(self, @resource)
            )
          end

          protected

          def order_columns
            %w(rand start_time)
          end

          def default_order_column
            "start_time"
          end

          def component_manifest
            "meetings"
          end

          def model_class
            Decidim::Meetings::Meeting
          end

          def collection
            query = filter_for_context(model_class)
            query = query.where(decidim_component_id: params.require(:component_id)) if params.has_key?(:component_id)
            query.published
          end

          def find_meeting!
            meeting = collection.find_by(id: resource_id)
            raise Decidim::RestFull::Core::ApiException::NotFound, "Meeting not found" unless meeting

            meeting
          end
        end
      end
    end
  end
end
