# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Meetings
        class MeetingExtendedDataController < Decidim::Api::RestFull::Core::ResourcesController
          include Decidim::Api::RestFull::ExtendedDataEndpoints

          before_action { doorkeeper_authorize! :meetings }
          before_action { ability.authorize! :read, ::Decidim::Meetings::Meeting }

          private

          def extended_data_resource
            @extended_data_resource ||= begin
              meeting = filter_for_context(Decidim::Meetings::Meeting).find_by(id: params.require(:id))
              raise Decidim::RestFull::Core::ApiException::NotFound, "Meeting not found" unless meeting

              meeting
            end
          end

          def extended_data_subject_class
            ::Decidim::Meetings::Meeting
          end
        end
      end
    end
  end
end
