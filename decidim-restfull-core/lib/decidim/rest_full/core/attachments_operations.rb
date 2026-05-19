# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      class AttachmentsOperations
        ATTACHED_TO_ALIASES = {
          "organization" => "Decidim::Organization",
          "Decidim::Organization" => "Decidim::Organization",
          "participatory_processes" => "Decidim::ParticipatoryProcess",
          "Decidim::ParticipatoryProcess" => "Decidim::ParticipatoryProcess"
        }.freeze

        OPTIONAL_ATTACHED_TO_ALIASES = [
          ["proposals", "Decidim::Proposals::Proposal"],
          ["proposal", "Decidim::Proposals::Proposal"],
          ["Decidim::Proposals::Proposal", "Decidim::Proposals::Proposal"],
          ["assemblies", "Decidim::Assembly"],
          ["Decidim::Assembly", "Decidim::Assembly"],
          ["conferences", "Decidim::Conference"],
          ["Decidim::Conference", "Decidim::Conference"],
          ["initiatives", "Decidim::Initiative"],
          ["Decidim::Initiative", "Decidim::Initiative"]
        ].freeze

        def initialize(context, params)
          @context = context
          @params = params
          @organization = context.organization
          @current_user = context.act_as
        end

        def index_scope
          scope = Decidim::Attachment.all
          scope = apply_filters(scope)
          scope.select { |attachment| organization_matches?(attachment) }
        end

        def find!(id)
          attachment = Decidim::Attachment.find_by(id:)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Attachment not found" unless attachment
          raise Decidim::RestFull::Core::ApiException::Forbidden unless organization_matches?(attachment)

          attachment
        end

        def create!
          attached_to = resolve_attached_to!(attached_to_type_param, attached_to_id_param)
          form = build_form(attached_to)
          Decidim::Admin::CreateAttachment.call(form, attached_to) do
            on(:ok) { |attachment| attachment }
            on(:invalid) { raise Decidim::RestFull::Core::ApiException::BadRequest, form_errors(form) }
          end
        end

        def update!(attachment)
          form = build_update_form(attachment)
          Decidim::Admin::UpdateAttachment.call(attachment, form) do
            on(:ok) { attachment.reload }
            on(:invalid) { raise Decidim::RestFull::Core::ApiException::BadRequest, form_errors(form) }
          end
        end

        def destroy!(attachment)
          Decidim.traceability.perform_action!("delete", attachment, @current_user) do
            attachment.destroy!
          end
          true
        end

        def direct_upload!
          blob = ActiveStorage::Blob.create_before_direct_upload!(
            filename: @params.require(:filename),
            byte_size: @params.require(:byte_size).to_i,
            checksum: @params.require(:checksum),
            content_type: @params[:content_type].presence || "application/octet-stream"
          )
          {
            signed_id: blob.signed_id,
            filename: blob.filename.to_s,
            content_type: blob.content_type,
            byte_size: blob.byte_size
          }
        end

        private

        def apply_filters(scope)
          filter = @params[:filter] || {}
          if filter[:attached_to_type].present? && filter[:attached_to_id].present?
            type = resolve_type_name(filter[:attached_to_type])
            scope = scope.where(attached_to_type: type, attached_to_id: filter[:attached_to_id])
          end
          scope = scope.where(attachment_collection_id: filter[:attachment_collection_id]) if filter[:attachment_collection_id].present?
          if filter[:file_type].present?
            scope = scope.to_a.select { |a| file_type_matches?(a, filter[:file_type]) }
            return scope
          end
          scope
        end

        def file_type_matches?(attachment, file_type)
          case file_type.to_s
          when "link" then attachment.link?
          when "image" then attachment.photo?
          when "document" then attachment.document? && !attachment.photo?
          else false
          end
        end

        def organization_matches?(attachment)
          attachment.organization&.id == @organization.id
        end

        def resolve_attached_to!(type_param, id_param)
          type = resolve_type_name(type_param)
          record = type.constantize.find_by(id: id_param)
          raise Decidim::RestFull::Core::ApiException::NotFound, "Attached resource not found" unless record
          raise Decidim::RestFull::Core::ApiException::Forbidden unless record_organization(record)&.id == @organization.id

          record
        end

        def record_organization(record)
          return record if record.is_a?(Decidim::Organization)
          return record.organization if record.respond_to?(:organization)

          nil
        end

        def attached_to_aliases
          @attached_to_aliases ||= begin
            aliases = ATTACHED_TO_ALIASES.dup
            OPTIONAL_ATTACHED_TO_ALIASES.each do |key, class_name|
              aliases[key] = class_name if Object.const_defined?(class_name)
            end
            aliases.freeze
          end
        end

        def resolve_type_name(value)
          key = value.to_s
          resolved = attached_to_aliases[key] || key
          raise Decidim::RestFull::Core::ApiException::BadRequest, "Unknown attached_to_type: #{value}" unless Object.const_defined?(resolved)

          resolved
        end

        def attached_to_type_param
          @params[:attached_to_type] || @params.dig(:data, :attributes, :attached_to_type) ||
            @params.dig(:data, "attributes", "attached_to_type")
        end

        def attached_to_id_param
          @params[:attached_to_id] || @params.dig(:data, :attributes, :attached_to_id) ||
            @params.dig(:data, "attributes", "attached_to_id")
        end

        def build_form(attached_to)
          Decidim::Admin::AttachmentForm.from_params(form_params(attached_to)).with_context(form_context(attached_to))
        end

        def build_update_form(attachment)
          Decidim::Admin::AttachmentForm.from_model(attachment).with_context(form_context(attachment.attached_to)).tap do |form|
            attrs = update_form_params
            form.title = attrs[:title] if attrs[:title]
            form.description = attrs[:description] if attrs[:description]
            form.weight = attrs[:weight] if attrs.has_key?(:weight)
            form.attachment_collection_id = attrs[:attachment_collection_id] if attrs.has_key?(:attachment_collection_id)
          end
        end

        def form_context(attached_to)
          {
            attached_to:,
            current_organization: @organization,
            current_user: @current_user
          }
        end

        def form_params(_attached_to)
          locale = @organization.default_locale
          {
            title: localized_hash(:title, locale),
            description: localized_hash(:description, locale),
            file: file_param,
            weight: @params[:weight] || 0,
            attachment_collection_id: @params[:attachment_collection_id]
          }.compact
        end

        def update_form_params
          locale = @organization.default_locale
          attrs = json_attributes
          {
            title: localized_from_attrs(:title, attrs, locale),
            description: localized_from_attrs(:description, attrs, locale),
            weight: attrs["weight"] || attrs[:weight],
            attachment_collection_id: attrs["attachment_collection_id"] || attrs[:attachment_collection_id]
          }.compact
        end

        def localized_hash(field, locale)
          value = @params[field] || @params[field.to_s]
          { locale => value.presence || @params.require(field) }
        end

        def localized_from_attrs(field, attrs, locale)
          val = attrs[field.to_s] || attrs[field.to_sym]
          return val if val.is_a?(Hash)

          { locale => val }
        end

        def file_param
          @params[:file] || @params[:signed_id] || json_attributes["signed_id"] || json_attributes[:signed_id]
        end

        def json_attributes
          data = @params[:data]
          return {} unless data

          data["attributes"] || data[:attributes] || {}
        end

        def form_errors(form)
          form.errors.full_messages.join(", ")
        end
      end
    end
  end
end
