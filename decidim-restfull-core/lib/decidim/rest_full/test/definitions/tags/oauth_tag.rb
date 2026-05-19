# frozen_string_literal: true

module Decidim
  module RestFull
    module Definitions
      module Tags
        OAUTH = {
          name: "OAuth",
          description: [
            <<~TXT.squish,
              Obtain access tokens for this API:
              **client_credentials** (machine-to-machine)
              or **password** with `auth_type` **login** or **impersonation**
              (Resource Owner Password Credentials flow).
            TXT
            "* **Machine-to-machine**: client credentials grant",
            "* **User**: ROPC with `auth_type` **login** or **impersonation**"
          ].join("\n"),

          externalDocs: {
            description: "How to authenticate",
            url: "#{Decidim::RestFull.config.docs_url}/category/authentication"
          }
        }.freeze
      end
    end
  end
end
