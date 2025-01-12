# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Proposal
        class ProposalsDraftsController < ResourcesController
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
            if update_keys.empty?
              return render json: Decidim::Api::RestFull::ProposalSerializer.new(
                draft,
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

            draft.title = { current_locale.to_s => form.title }
            draft.body = { current_locale.to_s => form.body }

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
            query.where("published_at is NULL AND decidim_coauthorships.decidim_author_id = ?",  act_as.id)
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

          def data
            params.require(:data)
          end
        end
      end
    end
  end
end
