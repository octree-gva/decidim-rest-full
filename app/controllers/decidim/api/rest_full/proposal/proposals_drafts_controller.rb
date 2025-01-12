# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposal
        class ProposalsDraftsController < ApplicationController
          before_action { doorkeeper_authorize! :proposals }
          before_action { ability.authorize! :draft, ::Decidim::Proposals::Proposal }

          def update
            payload = data.permit(:title, :body).to_h
            form = Decidim::Proposals::ProposalForm.from_model(draft).with_context(
              current_organization: current_organization,
              current_participatory_space: space,
              current_component: component
            )

            update_keys = payload.keys
            return  render json: Decidim::Api::RestFull::ProposalSerializer.new(
              draft,
              params: {
                only: [],
                publishable: form.valid?
              }
            ).serializable_hash if update_keys.size == 0 
            
            form.title = Rails::Html::FullSanitizer.new.sanitize(payload[:title]) if update_keys.include? "title"
            form.body = Rails::Html::FullSanitizer.new.sanitize(payload[:body]) if update_keys.include? "body"
            
            form.valid?
            update_errors = form.errors.select {|err| update_keys.include? err.attribute.to_s}
            raise Decidim::RestFull::ApiException::BadRequest, update_errors.map {|err| err.full_message}.join(". ") unless update_errors.size == 0
            draft.title =  { "#{current_locale}" => form.title }
            draft.body =  { "#{current_locale}" => form.body }

            draft.save(validate: false)
            draft.reload

            render json: Decidim::Api::RestFull::ProposalSerializer.new(
              draft,
              params: {
                only: [],
                locales: [current_locale.to_sym],
                publishable: form.valid?
              }
            ).serializable_hash
          end

          private

          def current_locale
            @current_locale ||= current_user.locale || current_organization.default_locale
          end

          def draft
            @draft ||= begin 
              match = Decidim::Proposals::Proposal.joins(:coauthorships).find_by(
                "decidim_coauthorships.decidim_author_id = ? AND published_at IS NULL", current_user.id
              )

              match || create_new_draft
            end
          end

          def create_new_draft 
            proposal = Decidim::Proposals::Proposal.new(component: component)
            coauthorship = proposal.coauthorships.build(author: current_user)
            proposal.coauthorships << coauthorship
            proposal.save(validate: false)
            proposal
          end

          def component
            @component = begin
              match = Decidim::Component.find_by(
                participatory_space_id: space_id,
                participatory_space_type: space_model_from(space_manifest).name,
                id: component_id,
                manifest_name: "proposals"
              )
              raise Decidim::RestFull::ApiException::BadRequest, "Component not found" unless match

              match
            end
          end

          def space_model_from(manifest)
            case manifest
            when :participatory_processes
              Decidim::ParticipatoryProcess
            when :assemblies
              Decidim::Assembly
            else
              raise Decidim::RestFull::ApiException::BadRequest, "manifest not supported: #{manifest}"
            end
          end

          def component_id
            @component_id ||= params.require(:component_id).to_i
          end

          def space_id
            @space_id ||= params.require(:id).to_i
          end

          def space_manifest
            @space_manifest ||= params.require(:manifest_name)
          end

          def space
            @space ||= begin
              raise Decidim::RestFull::ApiException::BadRequest, "Unkown space type #{space_manifest}" unless space_manifest_names.include?(space_manifest)

              match = space_model_from(space_manifest).find_by(id: space_id, organization: current_organization)
              raise Decidim::RestFull::ApiException::NotFound, "Space not found" unless match

              match
            end
          end

          def space_manifest_names
            @space_manifest_names ||= Decidim.participatory_space_registry.manifests.map(&:name)
          end

          def data
            params.require(:data)
          end
        end
      end
    end
  end
end
