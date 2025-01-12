# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposal
        class ProposalsDraftsController < ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :draft, ::Decidim::Proposals::Proposal }

          def show
            raise Decidim::RestFull::ApiException::NotFound, "Proposal Draft Not Found" unless draft

            form = Decidim::Proposals::ProposalForm.from_model(draft).with_context(
              current_organization: current_organization,
              current_participatory_space: space,
              current_component: component
            )

            render json: Decidim::Api::RestFull::ProposalDraftSerializer.new(
              draft,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                publishable: form.valid?
              }
            ).serializable_hash
          end

          def update
            payload = data.permit(:title, :body).to_h
            proposal_draft = draft || create_new_draft
            form = Decidim::Proposals::ProposalForm.from_model(proposal_draft).with_context(
              current_organization: current_organization,
              current_participatory_space: space,
              current_component: component
            )

            update_keys = payload.keys
            if update_keys.empty?
              return render json: Decidim::Api::RestFull::ProposalSerializer.new(
                proposal_draft,
                params: {
                  only: [],
                  publishable: form.valid?
                }
              ).serializable_hash
            end

            form.title = Rails::Html::FullSanitizer.new.sanitize(payload[:title]) if update_keys.include? "title"
            form.body = Rails::Html::FullSanitizer.new.sanitize(payload[:body]) if update_keys.include? "body"

            form.valid?
            update_errors = form.errors.select { |err| update_keys.include? err.attribute.to_s }
            raise Decidim::RestFull::ApiException::BadRequest, update_errors.map(&:full_message).join(". ") unless update_errors.empty?

            proposal_draft.title = { current_locale.to_s => form.title }
            proposal_draft.body = { current_locale.to_s => form.body }

            proposal_draft.save(validate: false)
            proposal_draft.reload

            render json: Decidim::Api::RestFull::ProposalDraftSerializer.new(
              proposal_draft,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                publishable: form.valid?
              }
            ).serializable_hash
          end

          private

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
            query = model_class.where(component: component)
            query.where("published_at is NULL AND decidim_coauthorships.decidim_author_id = ?", act_as.id)
          end

          def draft
            @draft ||= collection.joins(:rest_full_application).find_by(rest_full_application: { api_client_id: client_id })
          end

          def create_new_draft
            proposal = Decidim::Proposals::Proposal.new(component: component)
            coauthorship = proposal.coauthorships.build(author: current_user)
            proposal.coauthorships << coauthorship
            proposal.save(validate: false)
            proposal.update(
              rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: proposal.id, api_client_id: client_id)
            )
            proposal
          end

          def data
            params.require(:data)
          end
        end
      end
    end
  end
end
