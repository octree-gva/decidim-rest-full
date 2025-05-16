# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        OAUTH = {
          name: "OAuth",
          description: "Use OAuth to get tokens and interact with the API. You can use machine-to-machine tokens, or user token directly with the API." \
                       "\n* **Machine-to-machine**: Client Credential Flow" \
                       "\n* **User**: Resource Owner Password Credential Flow, with **impersonation** or **login**",

          externalDocs: {
            description: "How to authenticate",
            url: "#{Decidim::RestFull.docs_url}/category/authentication"
          }
        }.freeze
      end
    end
  end
end
