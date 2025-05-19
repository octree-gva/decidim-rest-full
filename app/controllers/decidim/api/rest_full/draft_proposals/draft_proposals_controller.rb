# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module DraftProposals
        class DraftProposalsController < ResourcesController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :draft, ::Decidim::Proposals::Proposal }
          before_action do
            raise Decidim::RestFull::ApiException::BadRequest, "User required" unless current_user
          end

          def show
            raise Decidim::RestFull::ApiException::NotFound, "Draft Proposal Not Found" unless draft

            form = form_for(draft)

            render json: Decidim::Api::RestFull::DraftProposalSerializer.new(
              draft,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                host: current_organization.host,
                publishable: form.valid?,
                fields: allowed_data_keys
              }
            ).serializable_hash
          end

          def create
            component_id = params.require(:data).require(:component_id)
            raise Decidim::RestFull::ApiException::BadRequest, "Draft Proposal already exists for this component" if collection.find_by(decidim_component_id: component_id)

            draft_proposal = create_new_draft(component_id)
            form = form_for(draft_proposal)
            render json: Decidim::Api::RestFull::DraftProposalSerializer.new(
              draft_proposal,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                host: current_organization.host,
                publishable: form.valid?,
                fields: allowed_data_keys
              }
            ).serializable_hash
          end

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

          def update
            raise Decidim::RestFull::ApiException::NotFound, "Draft Proposal Not Found" unless draft

            payload = data
            draft_proposal = draft
            form = form_for(draft_proposal)

            update_keys = payload.keys

            if update_keys.empty?
              return render json: Decidim::Api::RestFull::DraftProposalSerializer.new(
                draft_proposal,
                params: {
                  only: [],
                  locales: [current_locale.to_sym],
                  host: current_organization.host,
                  publishable: form.valid?,
                  fields: allowed_data_keys
                }
              ).serializable_hash
            end
            allowed_data_keys.each do |field_name|
              field_name_sym = field_name.to_sym
              form.send(:"#{field_name}=", Rails::Html::FullSanitizer.new.sanitize(payload[field_name_sym])) if update_keys.include? field_name
            end

            form.valid?
            update_errors = form.errors.select { |err| update_keys.include? err.attribute.to_s }
            raise Decidim::RestFull::ApiException::BadRequest, update_errors.map(&:full_message).join(". ") unless update_errors.empty?

            allowed_data_keys.each do |field_name|
              draft_proposal.send(:"#{field_name}=", { current_locale.to_s => form.send(field_name) })
            end

            draft_proposal.save(validate: false)
            draft_proposal.reload

            render json: Decidim::Api::RestFull::DraftProposalSerializer.new(
              draft_proposal,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                host: current_organization.host,
                publishable: form.valid?,
                fields: allowed_data_keys
              }
            ).serializable_hash
          end

          def destroy
            raise Decidim::RestFull::ApiException::NotFound, "Draft Proposal Not Found" unless draft

            serialized_draft = Decidim::Api::RestFull::DraftProposalSerializer.new(
              draft,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                host: current_organization.host,
                publishable: false,
                fields: allowed_data_keys
              }
            ).serializable_hash
            draft.destroy!
            render json: serialized_draft
          end

          private

          def form_for(resource)
            Decidim::Proposals::ProposalForm.from_model(resource).with_context(
              current_organization: current_organization,
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

          def create_new_draft(component_id)
            component = in_visible_spaces(Decidim::Component.all).find(component_id)
            raise Decidim::RestFull::ApiException::BadRequest, I18n.t("decidim.proposals.new.limit_reached").to_s if limit_reached?(component)

            proposal = Decidim::Proposals::Proposal.new(component: component, published_at: nil)
            raise ::ActiveRecord::RecordNotSaved, "Could not add new draft" unless proposal.save!(validate: false)

            coauthorship = proposal.coauthorships.build(author: current_user)
            proposal.coauthorships << coauthorship
            proposal.rest_full_application = Decidim::RestFull::ProposalApplicationId.new(proposal_id: proposal.id, api_client_id: client_id)
            raise ::ActiveRecord::RecordNotSaved, "Could not save draft relationships" unless proposal.save!(validate: false)

            proposal
          end

          def limit_reached?(component)
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
