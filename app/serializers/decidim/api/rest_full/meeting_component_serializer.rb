# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class MeetingComponentSerializer < ComponentSerializer
        meta do |component|
          additional_meta = [
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
          default_meta(component).merge(additional_meta)
        end
        def self.resources_for(component, act_as)
          Decidim::Meetings::Meeting.visible_for(act_as).where(decidim_component_id: component.id)
        end
        has_many :resources, meta: (proc do |component, params|
          { count: resources_for(component, params[:act_as]).count }
        end) do |component, params|
          resources_for(component, params[:act_as]).limit(50)
        end
      end
    end
  end
end
