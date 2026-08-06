# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      class Engine < ::Rails::Engine
        config.root = Proposals::ENGINE_ROOT

        config.to_prepare do
          next unless defined?(Decidim::Proposals)

          Decidim::Proposals::Proposal.include(Decidim::RestFull::Proposals::ProposalClientIdOverride)
          Decidim::Proposals::ProposalsController.include(Decidim::RestFull::Proposals::ProposalsControllerOverride)
          Decidim::RestFull::Proposals::Ransackers.register!
          Decidim::Proposals::Proposal.include(Decidim::RestFull::Core::HasExtendedData)
        end

        initializer "rest_full.proposals.extension" do
          Decidim::RestFull::Extension.register(:proposals) do |ext|
            ext.toggle_feature gem: "decidim-restfull-proposals"
            ext.controller_paths "proposals", "proposal_components", "draft_proposals", "vote_proposals"
            ext.oauth_scopes :proposals
            ext.permissions(:proposals, "proposals.read", group: :proposals)
            ext.permissions(:proposals, "proposals.draft", group: :proposals)
            ext.permissions(:proposals, "proposals.vote", group: :proposals)
            ext.permissions(:proposals, "proposals.extended_data.read", group: :proposals)
            ext.permissions(:proposals, "proposals.extended_data.update", group: :proposals)

            ext.api_job "draft_proposals#create", ->(ctx, p) { Proposals::DraftProposalsOperations.new(ctx, p).create! }
            ext.api_job "draft_proposals#update", ->(ctx, p) { Proposals::DraftProposalsOperations.new(ctx, p).update! }
            ext.api_job "draft_proposals#destroy", ->(ctx, p) { Proposals::DraftProposalsOperations.new(ctx, p).destroy! }
            ext.api_job "draft_proposals#publish", ->(ctx, p) { Proposals::DraftProposalsOperations.new(ctx, p).publish! }
            ext.api_job "vote_proposals#create", ->(ctx, p) { Proposals::VoteProposalsOperations.new(ctx, p).create! }

            {
              "draft_proposal_creation.succeeded" => :draft_proposal,
              "draft_proposal_update.succeeded" => :draft_proposal,
              "proposal_creation.succeeded" => :proposal,
              "proposal_update.succeeded" => :proposal,
              "proposal_state_change.succeeded" => :proposal
            }.each do |event_name, schema_ref|
              name = event_name
              ext.webhook_event(
                name,
                scope: :proposals,
                payload_schema_ref: schema_ref,
                schema_key: "wh_#{name.delete_suffix(".succeeded").tr(".", "_")}",
                trigger: "Proposal lifecycle notification",
                example: lambda { |organization|
                  ::Decidim::Api::RestFull::Proposals::ProposalWebhookSerializer.example_envelope(
                    organization,
                    event_name: name
                  )
                }
              )
            end

            ext.webhooks(
              /decidim\.events\./,
              /decidim\.proposals\./,
              handler: Decidim::RestFull::Core::WebhookDispatcher.instance.method(:handle_proposals)
            )

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
              ) do
                member do
                  resources :extended_data, only: [], controller: "/decidim/api/rest_full/proposals/proposal_extended_data" do
                    collection do
                      get "/", action: :index
                      put "/", action: :update
                      put "/sync", action: :update_sync
                    end
                  end
                end
              end

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

          Decidim::RestFull::Core::Configuration.events_for_proposals = %w(
            draft_proposal_creation.succeeded draft_proposal_update.succeeded
            proposal_creation.succeeded proposal_update.succeeded proposal_state_change.succeeded
          )
        end
      end
    end
  end
end
