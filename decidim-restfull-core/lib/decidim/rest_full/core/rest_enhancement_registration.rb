# frozen_string_literal: true

module Decidim
  module RestFull
    module Core
      # Immutable snapshot of one +rest_enhancement+ block (per Extension.register).
      RestEnhancementRegistration = Struct.new(
        :extension_name,
        :serializer_name,
        :http_cache_profile,
        :relationship_names,
        :relationship_installers,
        :link_installers,
        :meta_fragments,
        :cache_time_proc,
        :etag_segment_proc,
        keyword_init: true
      )
    end
  end
end
