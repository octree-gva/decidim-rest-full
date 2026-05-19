# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # DSL builder for +Extension#rest_enhancement+ (relationships, links, meta, http_cache).
      # rubocop:disable Naming/PredicateName -- mirrors FastJsonapi +has_many+ / +has_one+ API
      class RestEnhancementBuilder
        class HttpCacheBuilder
          def initialize(parent)
            @parent = parent
          end

          def cache_time(&block)
            @parent.cache_time_proc = block
          end

          def etag_segment(&block)
            @parent.etag_segment_proc = block
          end
        end

        attr_reader :extension_name, :serializer_name, :http_cache_profile
        attr_accessor :cache_time_proc, :etag_segment_proc

        def initialize(extension_name:, serializer_name:, http_cache_profile:)
          @extension_name = extension_name.to_sym
          @serializer_name = serializer_name.to_s
          @http_cache_profile = http_cache_profile&.to_sym
          @relationship_names = []
          @relationship_installers = []
          @link_names = []
          @link_installers = []
          @meta_fragments = []
        end

        def relationship(&block)
          instance_eval(&block) if block
        end

        def has_many(relationship_name, **options, &block)
          name = relationship_name.to_sym
          if @relationship_names.include?(name)
            raise ArgumentError,
                  "Duplicate rest_enhancement relationship :#{name} for #{@serializer_name} (#{@extension_name})"
          end

          @relationship_names << name
          @relationship_installers << proc { has_many(relationship_name, **options, &block) }
        end

        def has_one(relationship_name, **options, &block)
          name = relationship_name.to_sym
          if @relationship_names.include?(name)
            raise ArgumentError,
                  "Duplicate rest_enhancement relationship :#{name} for #{@serializer_name} (#{@extension_name})"
          end

          @relationship_names << name
          @relationship_installers << proc { has_one(relationship_name, **options, &block) }
        end

        def link(link_name, &block)
          key = link_name.to_sym
          if @link_names.include?(key)
            raise ArgumentError,
                  "Duplicate rest_enhancement link :#{link_name} for #{@serializer_name} (#{@extension_name})"
          end

          @link_names << key
          @link_installers << proc { link(link_name, &block) }
        end

        def meta(&block)
          @meta_fragments << block
        end

        def http_cache(&block)
          HttpCacheBuilder.new(self).instance_eval(&block) if block
        end

        def validate_http_cache_strictness!
          return unless http_cache_profile
          return unless @relationship_names.any? || @meta_fragments.any?
          return if cache_time_proc || etag_segment_proc

          msg = "rest_enhancement for #{serializer_name} (#{extension_name}): http_cache_profile #{http_cache_profile.inspect} " \
                "is set with relationship/meta but no cache_time or etag_segment — conditional GET may return stale 304. " \
                "See website/docs/dev/add-endpoint/http-cache.md"

          if Decidim::RestFull.config.strict_rest_enhancement_http_cache
            raise ArgumentError, msg
          elsif defined?(Rails) && Rails.logger
            Rails.logger.warn("[Decidim::RestFull] #{msg}")
          end
        end

        def to_registration
          RestEnhancementRegistration.new(
            extension_name:,
            serializer_name:,
            http_cache_profile:,
            relationship_names: @relationship_names.dup,
            relationship_installers: @relationship_installers.dup,
            link_installers: @link_installers.dup,
            meta_fragments: @meta_fragments.dup,
            cache_time_proc:,
            etag_segment_proc:
          )
        end
      end
      # rubocop:enable Naming/PredicateName
    end
  end
end
