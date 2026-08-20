# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Meetings
        class MeetingSerializer < ::Decidim::Api::RestFull::Core::ResourceSerializer
          set_type :meeting
        end
      end
    end
  end
end
