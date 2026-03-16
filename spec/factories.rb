# frozen_string_literal: true

require "decidim/core/test/factories"

require "decidim/participatory_processes/test/factories"
require "decidim/proposals/test/factories"
require "decidim/meetings/test/factories"
require "decidim/accountability/test/factories"
require "decidim/system/test/factories"
require "decidim/blogs/test/factories"
require "decidim/initiatives/test/factories" if defined?(Decidim::Initiatives)
require "decidim/conferences/test/factories" if defined?(Decidim::Conferences)

require "decidim/rest_full/test/factories"
