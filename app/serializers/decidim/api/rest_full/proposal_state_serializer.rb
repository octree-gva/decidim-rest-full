# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      class ProposalStateSerializer < ResourceSerializer
        def self.default_meta(state)
          scope = state.component.scope || state.participatory_space.scope
          metas = {}
          metas[:scope] = scope.id if scope
          metas
        end

        meta do |state, _params|
          metas = default_meta(state)
          metas
        end

        attributes :token, :bg_color, :text_color

        attribute :title do |state, params|
          translated_field(state.title, params[:locales])
        end

        attribute :announcement_title do |state, params|
          translated_field(state.announcement_title, params[:locales])
        end

        has_many :proposals, meta: (proc do |state, _params|
          { count: state.proposals.count }
        end) do |state, _params|
          state.proposals
        end
      end
    end
  end
end
