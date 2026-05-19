# frozen_string_literal: true

module Decidim
  module RestFull
    module Proposals
      # Shared imperative logic for draft proposals (sync controller + async ApiJob).
      class DraftProposalsOperations
        SPACE_MANIFEST_MODELS = Decidim::Api::RestFull::ApplicationController::SPACE_MANIFEST_MODELS

        def initialize(execution_context, params)
          @ctx = execution_context
          @params = params.is_a?(ActionController::Parameters) ? params : ActionController::Parameters.new(params)
        end

        def create!
          require_user!
          component_id = @params.require(:data).require(:component_id)
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Draft Proposal already exists for this component" if collection.find_by(decidim_component_id: component_id)

          draft_proposal = create_new_draft(component_id)
          form = form_for(draft_proposal)
          serialize_draft(draft_proposal, form)
        end

        def update!
          require_user!
          raise Decidim::RestFull::Core::ApiException::NotFound, "Draft Proposal Not Found" unless draft_record

          payload = data
          return serialize_draft(draft_record.reload, form_for(draft_record)) if payload.keys.empty?

          form = form_for(draft_record)
          apply_payload_to_form(form, payload)
          validate_form_for_update!(form, payload.keys)
          copy_form_to_draft_and_save(draft_record, form)
          serialize_draft(draft_record.reload, form_for(draft_record.reload))
        end

        def destroy!
          require_user!
          raise Decidim::RestFull::Core::ApiException::NotFound, "Draft Proposal Not Found" unless draft_record

          serialized_draft = serialize_draft(draft_record, form_for(draft_record), publishable: false)
          draft_record.destroy!
          serialized_draft
        end

        def publish!
          require_user!
          raise Decidim::RestFull::Core::ApiException::NotFound, "Draft Proposal Not Found" unless draft_record

          form = form_for(draft_record)
          raise Decidim::RestFull::Core::ApiException::BadRequest, form.errors.full_messages.join(". ") unless form.valid?

          draft_record.update!(published_at: Time.now.utc)
          published = nil
          exec_ctx = @ctx
          Decidim::Proposals::PublishProposal.call(draft_record, current_user) do
            on(:ok) do
              published = Decidim::Api::RestFull::Proposals::ProposalSerializer.new(
                draft_record,
                params: {
                  locales: available_locales,
                  host: organization.host,
                  act_as: exec_ctx.act_as,
                  client_id: exec_ctx.client_id
                }
              ).serializable_hash
            end
            on(:invalid) do
              raise Decidim::RestFull::Core::ApiException::BadRequest, form.errors.full_messages.join(". ") unless form.valid?
            end
          end
          published
        end

        private

        attr_reader :ctx

        delegate :organization, :current_user, :act_as, :client_id, :available_locales, to: :ctx

        def participatory_space_visibility
          @participatory_space_visibility ||= Decidim::RestFull::ParticipatorySpaceVisibility.new(organization:, act_as:)
        end

        delegate :in_visible_spaces, :visible_spaces, :visible_scope_for, :space_class_from_name, to: :participatory_space_visibility

        def require_user!
          u = current_user
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User required" unless u
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User blocked" if u.blocked_at
          raise Decidim::RestFull::Core::ApiException::BadRequest, "User locked" if u.locked_at
        end

        def filter_for_context(query)
          components_filters = Decidim::Component.all
          if @params.has_key?(:space_manifest)
            components_filters = components_filters.where(participatory_space_type: space_class_from_name(@params.require(:space_manifest)))
            components_filters = components_filters.where(participatory_space_id: @params.require(:space_id)) if @params.has_key?(:space_id)
          end
          query.where(decidim_component_id: in_visible_spaces(components_filters).ids)
        end

        def available_space_manifest_names
          SPACE_MANIFEST_MODELS.keys.select do |m|
            name = SPACE_MANIFEST_MODELS[m]
            name.present? && Object.const_defined?(name)
          end
        end

        def model_class
          Decidim::Proposals::Proposal.joins(:coauthorships)
        end

        def collection
          query = filter_for_context(model_class)
          query.where("published_at is NULL AND decidim_coauthorships.decidim_author_id = ?", act_as.id)
        end

        def draft_record
          @draft_record ||= collection.joins(:rest_full_application).where(rest_full_application: { api_client_id: client_id }).find_by(id: @params.require(:id))
        end

        def create_new_draft(component_id)
          component = in_visible_spaces(Decidim::Component.all).find(component_id)
          raise Decidim::RestFull::Core::ApiException::BadRequest, I18n.t("decidim.proposals.new.limit_reached").to_s if limit_reached?(component)

          proposal = Decidim::Proposals::Proposal.new(component:, published_at: nil)
          raise ::ActiveRecord::RecordNotSaved, "Could not add new draft" unless proposal.save!(validate: false)

          coauthorship = proposal.coauthorships.build(author: current_user)
          proposal.coauthorships << coauthorship
          proposal.rest_full_application = Decidim::RestFull::Proposals::ProposalApplicationId.new(proposal_id: proposal.id, api_client_id: client_id)
          raise ::ActiveRecord::RecordNotSaved, "Could not save draft relationships" unless proposal.save!(validate: false)

          proposal
        end

        def limit_reached?(component)
          proposal_limit = component.settings.proposal_limit
          return false if proposal_limit.zero?

          query = model_class.where(component:)
          current_user_proposals_count = query.where("published_at IS NOT NULL AND decidim_coauthorships.decidim_author_id = ?", act_as.id).count
          current_user_proposals_count >= proposal_limit
        end

        def data
          @data ||= begin
            data_payload = if @params.has_key?(:data)
                             @params[:data].permit!.to_h
                           else
                             {}
                           end
            data_payload.select { |k| allowed_data_keys.include? k }
          end
        end

        def allowed_data_keys
          %w(title body)
        end

        def form_for(resource)
          Decidim::Proposals::ProposalForm.from_model(resource).with_context(
            current_organization: organization,
            current_component: resource.component
          )
        end

        def serialize_draft(draft_proposal, form, publishable: nil)
          pub = publishable.nil? ? form.valid? : publishable
          Decidim::Api::RestFull::Proposals::DraftProposalSerializer.new(
            draft_proposal,
            params: {
              only: [],
              locales: [current_locale.to_sym],
              host: organization.host,
              publishable: pub,
              fields: allowed_data_keys
            }
          ).serializable_hash
        end

        def current_locale
          @ctx.current_locale
        end

        def apply_payload_to_form(form, payload)
          sanitizer = Rails::Html::FullSanitizer.new
          allowed_data_keys.each do |field_name|
            next unless payload.has_key?(field_name.to_sym)

            form.public_send(:"#{field_name}=", sanitizer.sanitize(payload[field_name.to_sym]))
          end
        end

        def validate_form_for_update!(form, update_keys)
          form.valid?
          update_errors = form.errors.select { |err| update_keys.include?(err.attribute.to_s) }
          return if update_errors.empty?

          raise Decidim::RestFull::Core::ApiException::BadRequest, update_errors.map(&:full_message).join(". ")
        end

        def copy_form_to_draft_and_save(draft_proposal, form)
          allowed_data_keys.each do |field_name|
            value = form.public_send(field_name)
            draft_proposal.public_send(:"#{field_name}=", { current_locale.to_s => value })
          end
          draft_proposal.save(validate: false)
        end
      end
    end
  end
end
