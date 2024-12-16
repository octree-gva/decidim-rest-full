# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Blog
        class BlogsController < ApplicationController
          before_action { doorkeeper_authorize! :blog }

          # Index all blog for the given component
          def index
          end

          def show
            resource = model_class.find_by(
              component: component,
              id: resource_id
            )
            raise Decidim::RestFull::ApiException::NotFound, "Blog Post Not Found" unless resource

            render json: Decidim::Api::RestFull::BlogSerializer.new(
              resource,
              params: {
                only: [],
                locales: available_locales,
                host: current_organization.host,
                act_as: act_as
              }
            ).serializable_hash
          end

          private

          def model_class
            Decidim::Blogs::Post
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

          def component
            @component = begin
              raise Decidim::RestFull::ApiException::BadRequest, "Unkown component type #{component_manifest}" unless component_manifest_names.include? component_manifest

              match = Decidim::Component.find_by(
                participatory_space_id: space_id,
                participatory_space_type: space_model_from(space_manifest).name,
                id: component_id
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

          def space_manifest_names
            @space_manifest_names ||= Decidim.participatory_space_registry.manifests.map(&:name)
          end

          def component_manifest_names
            @component_manifest_names ||= Decidim.component_registry.manifests.map(&:name)
          end

          def component_id
            @component_id ||= params.require(:component_id).to_i
          end

          def component_manifest
            @component_manifest ||= params.require(:component_manifest_name)
          end

          def resource_id
            @resource_id ||= params.require(:resource_id).to_i
          end
        end
      end
    end
  end
end
