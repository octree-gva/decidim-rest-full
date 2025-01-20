# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposal
        class DraftProposalsController < ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :draft, ::Decidim::Proposals::Proposal }

          def publish
            raise Decidim::RestFull::ApiException::NotFound, "Draft Proposal Not Found" unless draft

            form = form_for(draft)
            raise Decidim::RestFull::ApiException::BadRequest, form.errors.full_messages.join(". ") unless form.valid?

            draft.update!(published_at: Time.now.utc)
            Decidim::Proposals::PublishProposal.call(draft, current_user) do
              on(:ok) do
                render json: Decidim::Api::RestFull::ProposalSerializer.new(
                  draft,
                  params: {
                    locales: available_locales,
                    host: current_organization.host,
                    act_as: act_as
                  }
                ).serializable_hash
              end

              on(:invalid) do
                raise Decidim::RestFull::ApiException::BadRequest, form.errors.full_messages.join(". ") unless form.valid?
              end
            end
          end

          def show
            raise Decidim::RestFull::ApiException::NotFound, "Draft Proposal Not Found" unless draft

            form = form_for(draft)

            render json: Decidim::Api::RestFull::DraftProposalSerializer.new(
              draft,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                publishable: form.valid?
              }
            ).serializable_hash
          end

          def update
            payload = data
            draft_proposal = draft || create_new_draft
            form = form_for(draft_proposal)

            update_keys = payload.keys
            if update_keys.empty?
              return render json: Decidim::Api::RestFull::DraftProposalSerializer.new(
                draft_proposal,
                params: {
                  only: [],
                  locales: [current_locale.to_sym],
                  publishable: form.valid?
                }
              ).serializable_hash
            end

            form.title = Rails::Html::FullSanitizer.new.sanitize(payload[:title]) if update_keys.include? "title"
            form.body = Rails::Html::FullSanitizer.new.sanitize(payload[:body]) if update_keys.include? "body"

            form.valid?
            update_errors = form.errors.select { |err| update_keys.include? err.attribute.to_s }
            raise Decidim::RestFull::ApiException::BadRequest, update_errors.map(&:full_message).join(". ") unless update_errors.empty?

            draft_proposal.title = { current_locale.to_s => form.title }
            draft_proposal.body = { current_locale.to_s => form.body }

            draft_proposal.save(validate: false)
            draft_proposal.reload

            render json: Decidim::Api::RestFull::DraftProposalSerializer.new(
              draft_proposal,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                publishable: form.valid?
              }
            ).serializable_hash
          end

          def destroy
            raise Decidim::RestFull::ApiException::NotFound, "Draft Proposal Not Found" unless draft

            draft.destroy!
            render json: Decidim::Api::RestFull::DraftProposalSerializer.new(
              draft,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                publishable: false
              }
            ).serializable_hash
          end

          private

          def form_for(resource)
            Decidim::Proposals::ProposalForm.from_model(resource).with_context(
              current_organization: current_organization,
              current_participatory_space: space,
              current_component: component
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
            query = model_class.where(component: component)
            query.where("published_at is NULL AND decidim_coauthorships.decidim_author_id = ?", act_as.id)
          end

          def draft
            @draft ||= collection.joins(:rest_full_application).find_by(rest_full_application: { api_client_id: client_id })
          end

          def create_new_draft
            raise Decidim::RestFull::ApiException::BadRequest, I18n.t("decidim.proposals.new.limit_reached") if limit_reached?

            proposal = Decidim::Proposals::Proposal.new(component: component)
            coauthorship = proposal.coauthorships.build(author: current_user)
            proposal.coauthorships << coauthorship
            proposal.save(validate: false)
            proposal.update(
              rest_full_application: Decidim::RestFull::ProposalApplicationId.new(proposal_id: proposal.id, api_client_id: client_id)
            )
            proposal
          end

          def limit_reached?
            proposal_limit = component.settings.proposal_limit

            return false if proposal_limit.zero?

            query = model_class.where(component: component)
            current_user_proposals_count = query.where("published_at IS NOT NULL AND decidim_coauthorships.decidim_author_id = ?", act_as.id).count
            current_user_proposals_count >= proposal_limit
          end

          def data
            @data ||= begin
              data_payload = if params.has_key? :data
                               params[:data].permit!.to_h
                             else
                               {}
                             end
              data_payload.select { |k| allowed_data_keys.include? k }
            end
          end

          def allowed_data_keys
            %w(title body)
          end
        end
      end
    end
  end
end
