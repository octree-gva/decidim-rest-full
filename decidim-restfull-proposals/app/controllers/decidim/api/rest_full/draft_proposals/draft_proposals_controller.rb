# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module DraftProposals
        # CRUD for draft proposals (unpublished). Uses Decidim ProposalForm for validation.
        # Allowed writable fields: title, body (see allowed_data_keys). Update applies
        # payload to form, validates, then copies to draft and saves.
        class DraftProposalsController < Decidim::Api::RestFull::Core::ResourcesController
          include Decidim::Api::RestFull::AsyncApiJobEnqueuing

          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :draft, ::Decidim::Proposals::Proposal }

          before_action { require_user! }

          def show
            raise Decidim::RestFull::Core::ApiException::NotFound, "Draft Proposal Not Found" unless draft

            form = form_for(draft)
            payload = Decidim::Api::RestFull::Proposals::DraftProposalSerializer.new(
              draft,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                host: current_organization.host,
                publishable: form.valid?,
                fields: allowed_data_keys
              }
            ).serializable_hash
            render_json_with_conditional_get(payload, fingerprint: resource_fingerprint_for(draft))
          end

          def create
            enqueue_rest_full_api_job!("draft_proposals#create")
          end

          def create_sync
            render json: (Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Proposals::DraftProposalsOperations.new(api_execution_context, params).create!
            end)
          end

          def publish
            enqueue_rest_full_api_job!("draft_proposals#publish")
          end

          def publish_sync
            render json: (Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Proposals::DraftProposalsOperations.new(api_execution_context, params).publish!
            end)
          end

          def update
            enqueue_rest_full_api_job!("draft_proposals#update")
          end

          def update_sync
            render json: (Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Proposals::DraftProposalsOperations.new(api_execution_context, params).update!
            end)
          end

          def destroy
            enqueue_rest_full_api_job!("draft_proposals#destroy")
          end

          def destroy_sync
            render json: (Decidim::RestFull::SyncRunner.call do
              Decidim::RestFull::Proposals::DraftProposalsOperations.new(api_execution_context, params).destroy!
            end)
          end

          private

          def form_for(resource)
            Decidim::Proposals::ProposalForm.from_model(resource).with_context(
              current_organization:,
              current_component: resource.component
            )
          end

          def order_columns
            ["rand"]
          end

          def default_order_column
            "rand"
          end

          def component_manifest
            "proposals"
          end

          def model_class
            Decidim::Proposals::Proposal.joins(:coauthorships)
          end

          def collection
            query = filter_for_context(model_class)
            query.where("published_at is NULL AND decidim_coauthorships.decidim_author_id = ?", act_as.id)
          end

          def draft
            @draft ||= collection.joins(:rest_full_application).where(rest_full_application: { api_client_id: client_id }).find(params.require(:id))
          end

          def allowed_data_keys
            %w(title body)
          end
        end
      end
    end
  end
end
