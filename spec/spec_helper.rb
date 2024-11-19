# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["NODE_ENV"] ||= "test"
ENV["ENGINE_ROOT"] = File.dirname(__dir__)

require "decidim/dev"

Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"
require "decidim/core/test/factories"
require "decidim/rest_full/test/definitions/error"
require "decidim/rest_full/test/definitions/organization"
require "decidim/rest_full/test/definitions/password_grant"
require "decidim/rest_full/test/definitions/client_credential_grant"
require "decidim/rest_full/test/definitions/populate_param"
require "decidim/rest_full/test/definitions/locales_param"

require "rswag/specs"
require "swagger_helper"
