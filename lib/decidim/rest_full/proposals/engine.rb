# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      class Engine < ::Rails::Engine
        config.root = Pathname.new(File.expand_path("../../../..", __dir__))

        config.to_prepare do
          next unless Decidim::RestFull::Core::Configuration.enable_proposals_api
          next unless defined?(Decidim::Proposals)

          Decidim::Proposals::Proposal.include(Decidim::RestFull::Proposals::ProposalClientIdOverride)
          Decidim::Proposals::ProposalsController.include(Decidim::RestFull::Proposals::ProposalsControllerOverride)
        end

        initializer "rest_full.proposals.webhooks" do
          if Decidim::RestFull::Core::Configuration.enable_proposals_api
            ActiveSupport::Notifications.subscribe(/decidim\.events\./) do |event_name, data|
              Decidim::RestFull::Core::WebhookDispatcher.instance.handle_proposals(event_name, data)
            end
            ActiveSupport::Notifications.subscribe(/decidim\.proposals\./) do |event_name, data|
              Decidim::RestFull::Core::WebhookDispatcher.instance.handle_proposals(event_name, data)
            end
          end
        end

        initializer "rest_full.proposals.permissions" do
          if Decidim::RestFull::Core::Configuration.enable_proposals_api
            registry = Decidim::RestFull::Core::PermissionRegistry
            registry.register(:proposals, "proposals.read", group: :proposals)
            registry.register(:proposals, "proposals.draft", group: :proposals)
            registry.register(:proposals, "proposals.vote", group: :proposals)
          end
        end

        initializer "rest_full.proposals.routes" do
          Decidim::RestFull::Core::RouteRegistry.draw_api_routes do
            constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_proposals_api }) do
              resources :components, only: [] do
                collection do
                  resources :proposal_components,
                            only: [:index, :show],
                            controller: "/decidim/api/rest_full/components/proposal_components"
                end
              end

              resources :proposals,
                        only: [:index, :show],
                        controller: "/decidim/api/rest_full/proposals/proposals"

              resources :draft_proposals,
                        only: [:index, :show, :update, :create, :destroy],
                        controller: "/decidim/api/rest_full/draft_proposals/draft_proposals" do
                member do
                  post "/publish", action: :publish
                end
              end

              resources :proposal_votes,
                        only: [:create],
                        controller: "/decidim/api/rest_full/proposal_votes/proposal_votes"
            end
          end
        end
      end
    end
  end
end
