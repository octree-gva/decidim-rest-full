# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class MeetingComponentSerializer < ComponentSerializer
        meta do |component|
          [
            :default_registration_terms,
            :comments_enabled,
            :comments_max_length,
            :registration_code_enabled,
            :creation_enabled_for_participants
          ].to_h do |meta_sym|
            settings = settings_for(component)
            value = false
            value = settings[meta_sym.to_s] if settings.has_key? meta_sym.to_s
            [meta_sym.to_s, value]
          end
        end
        has_many :resources do |component, params|
          Decidim::Meetings::Meeting.visible_for(params[:act_as]).where(decidim_component_id: component.id).limit(50)
        end
      end
    end
  end
end
