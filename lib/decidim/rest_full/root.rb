# frozen_string_literal: true

module Decidim
  module RestFull
    class Root < Grape::API
      format :json
      mount Decidim::RestFull::System::API, at: "/system"
      mount Decidim::RestFull::Spaces::API, at: "/spaces"
      
      add_swagger_documentation \
        mount_path: "/docs/openapi.json",
        tags: [
          { name: "system", description: "Manage Decidim Tenants and global system configurations" }
        ]
    end
  end
end
