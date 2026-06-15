# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      class Engine < ::Rails::Engine
        config.root = Proposals::ENGINE_ROOT

        config.to_prepare do
          next unless Decidim::RestFull::Core::Configuration.enable_proposals_api
          next unless defined?(Decidim::Proposals)

          Decidim::Proposals::Proposal.include(Decidim::RestFull::Proposals::ProposalClientIdOverride)
          Decidim::Proposals::ProposalsController.include(Decidim::RestFull::Proposals::ProposalsControllerOverride)
          Decidim::RestFull::Proposals::Ransackers.register!
        end

        initializer "rest_full.proposals.extension" do
          next unless Decidim::RestFull::Core::Configuration.enable_proposals_api

          Decidim::RestFull::Extension.register(:proposals) do |ext|
            ext.oauth_scopes :proposals
            ext.permissions(:proposals, "proposals.read", group: :proposals)
            ext.permissions(:proposals, "proposals.draft", group: :proposals)
            ext.permissions(:proposals, "proposals.vote", group: :proposals)

            ext.api_job "draft_proposals#create", ->(ctx, p) { Proposals::DraftProposalsOperations.new(ctx, p).create! }
            ext.api_job "draft_proposals#update", ->(ctx, p) { Proposals::DraftProposalsOperations.new(ctx, p).update! }
            ext.api_job "draft_proposals#destroy", ->(ctx, p) { Proposals::DraftProposalsOperations.new(ctx, p).destroy! }
            ext.api_job "draft_proposals#publish", ->(ctx, p) { Proposals::DraftProposalsOperations.new(ctx, p).publish! }
            ext.api_job "vote_proposals#create", ->(ctx, p) { Proposals::VoteProposalsOperations.new(ctx, p).create! }
            ext.webhooks(/decidim\.events\./, /decidim\.proposals\./)

            ext.open_api_definitions(
              File.join(Proposals::ENGINE_ROOT, "lib/decidim/rest_full/proposals/test_definitions.rb")
            )

            ext.rswag_specs(
              File.join(Proposals::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/proposals/**/*_spec.rb"),
              File.join(Proposals::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/draft_proposals/**/*_spec.rb"),
              File.join(Proposals::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/vote_proposals/**/*_spec.rb"),
              File.join(Proposals::ENGINE_ROOT, "spec/requests/decidim/api/rest_full/components/proposal_components*_spec.rb")
            )

            ext.routes do
              constraints(->(_req) { Decidim::RestFull::Core::Configuration.enable_proposals_api }) do
                resources :components, only: [] do
                  collection do
                    Decidim::RestFull::Routing.read_resources(
                      self,
                      :proposal_components,
                      controller: "components/proposal_components",
                      only: [:index, :show]
                    )
                  end
                end

                Decidim::RestFull::Routing.read_resources(
                  self,
                  :proposals,
                  controller: "proposals/proposals",
                  only: [:index, :show]
                )

                Decidim::RestFull::Routing.async_resources(
                  self,
                  :draft_proposals,
                  controller: "draft_proposals/draft_proposals",
                  only: [:index, :show, :update, :create, :destroy],
                  member: { post: { publish: :publish, "publish/sync": :publish_sync } }
                )

                Decidim::RestFull::Routing.async_resources(
                  self,
                  :vote_proposals,
                  controller: "vote_proposals/vote_proposals",
                  only: [:index, :show, :create, :destroy]
                )
              end
            end
          end
        end
      end
    end
  end
end
