# frozen_string_literal: true

module Decidim
  module RestFull
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::RestFull

      config.to_prepare do
        Decidim::Organization.include(Decidim::RestFull::OrganizationClientIdsOverride)
      end

      initializer "rest_full.scopes" do
        Doorkeeper.configure do
          # Define default and optional scopes
          default_scopes :public
          optional_scopes :spaces, :system, :proposals, :meetings, :debates, :pages, :public

          # Enable resource owner password credentials
          grant_flows %w(password client_credentials)

          # Authenticate resource owner
          resource_owner_from_credentials do |_routes|
            # forbid system scope, exclusive to credential flow
            raise ::Doorkeeper::Errors::DoorkeeperError, "can not request system scope with ROPC flow" if (params["scope"] || "").include? "system"

            auth_type = params.require(:auth_type)
            current_organization = request.env["decidim.current_organization"]
            raise ::Doorkeeper::Errors::DoorkeeperError, "Invalid Organization. Check requested host." unless current_organization

            client_id = params.require("client_id")
            raise ::Doorkeeper::Errors::DoorkeeperError, "Invalid Api Client, check client_id credentials" if client_id.size < 8

            api_client = Decidim::RestFull::ApiClient.find_by(
              uid: client_id,

              organization: current_organization
            )
            raise ::Doorkeeper::Errors::DoorkeeperError, "Invalid Api Client, check credentials" unless api_client

            case auth_type
            when "impersonate"
              username = params.require("username")
              user = Decidim::User.find_by(
                nickname: username,
                organization: current_organization
              )
              unless user
                default_meta = {
                  "register_on_missing" => false,
                  "accept_tos_on_register" => false,
                  "skip_confirmation_on_register" => false,
                  "email" => "#{username}@example.org",
                  "name" => username.titleize
                }
                user_meta = if params[:meta]
                              params[:meta].permit(
                                :register_on_missing,
                                :accept_tos_on_register,
                                :skip_confirmation_on_register,
                                :name,
                                :email
                              ).to_h
                            else
                              {}
                            end
                meta = default_meta.merge(user_meta)
                extra = if params.has_key? :extra
                          params[:extra].permit!.to_h
                        else
                          {}
                        end
                raise ::Doorkeeper::Errors::DoorkeeperError, "User not found" unless meta["register_on_missing"]

                email = meta.delete("email")
                name = meta.delete("name")
                user = current_organization.users.build(
                  email: email,
                  name: name,
                  nickname: username,
                  extended_data: extra
                )
                user.accepted_tos_version = if meta["accept_tos_on_register"]
                                              current_organization.tos_version + 1.hour
                                            else
                                              # Will need to revalidate tos
                                              current_organization.tos_version - 1.hour
                                            end
                user.tos_agreement = true

                password = begin
                  special_chars = ["@", "#", "$", "%", "^", "&", "*", "-", "_", "+", "=", "~"]
                  part1 = ::Devise.friendly_token.first((20 + 1) / 2)
                  special_part = special_chars.sample(2).join
                  part2 = ::Devise.friendly_token.first((20 + 1) / 2)

                  # Combine parts to form the final password
                  password = part1 + special_part + part2
                  password.chars.shuffle.join
                end
                user.password = user.password_confirmation = password
                user.skip_confirmation! if meta["skip_confirmation_on_register"]
                user.save!
              end
              user
            when "login"
              user = Decidim::User.find_by(
                nickname: params.require("username"),
                organization: current_organization
              )
              raise ::Doorkeeper::Errors::DoorkeeperError, "User not found" unless user.valid_password?(params.require("password"))

              user
            else
              raise ::Doorkeeper::Errors::DoorkeeperError, "Not allowed param auth_type='#{auth_type}'"
            end
          end
        end
      end
      initializer "rest_full.menu" do
        Decidim::RestFull::Menu.register_system_menu!
      end
    end
  end
end
