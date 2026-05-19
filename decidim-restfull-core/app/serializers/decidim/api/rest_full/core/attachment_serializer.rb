# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Core
        class AttachmentSerializer
          include JSONAPI::Serializer

          set_type :attachment

          attribute :title do |object|
            Core::AttachmentSerializer.localized_json(object.title)
          end

          attribute :description do |object|
            Core::AttachmentSerializer.localized_json(object.description)
          end

          attribute :weight, &:weight

          attribute :attachment_collection_id, &:attachment_collection_id

          attribute :file_type do |object|
            if object.link?
              "link"
            elsif object.photo?
              "image"
            else
              "document"
            end
          end

          attribute :content_type, &:content_type

          attribute :url do |object|
            next object.link if object.link?

            Decidim::AttachmentPresenter.new(object).attachment_url
          rescue StandardError
            nil
          end

          attribute :thumbnail_url do |object|
            next unless object.photo?

            Decidim::AttachmentPresenter.new(object).thumbnail_url
          rescue StandardError
            nil
          end

          attribute :attached_to do |object|
            {
              type: object.attached_to_type,
              id: object.attached_to_id
            }
          end

          attribute :created_at do |object|
            object.created_at.iso8601
          end

          attribute :updated_at do |object|
            object.updated_at.iso8601
          end

          def self.localized_json(hash)
            return hash unless hash.is_a?(Hash)

            hash.slice(*Decidim.available_locales.map(&:to_s))
          end
        end
      end
    end
  end
end
