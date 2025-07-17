# frozen_string_literal: true

module Decidim
  module Api
    module RestFull
      module Metrics
        class HealthController < ApplicationController
          before_action :check_feature
          def index
            status = :ok

            each_check do |result|
              unless result
                status = :service_unavailable
                break
              end
            end

            msg = status == :ok ? "OK" : "ERROR"
            return head(status) if request.method == "HEAD"

            render json: { message: msg }, status: status
          end

          private

          def check_feature
            raise AbstractController::ActionNotFound unless Decidim::RestFull.feature.health?
          end

          def each_check
            checks = [
              -> { check_db },
              -> { check_cache },
              -> { check_asset },
              -> { check_referer }
            ]

            checks.each do |check_proc|
              yield check_proc.call
            end
          end

          def check_db
            ActiveRecord::Base.connection.active?
          rescue StandardError
            false
          end

          def check_cache
            v = Time.zone.now.to_s
            Rails.cache.write("health_check", v)
            Rails.cache.read("health_check") == v
          rescue StandardError
            false
          end

          def check_asset
            asset_file = "media/images/default-avatar.svg"
            asset_relative_path = ActionController::Base.helpers.asset_pack_url(asset_file)
            asset_url = URI.join(request.base_url, asset_relative_path).to_s

            uri = URI.parse(asset_url)
            response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
              http.head(uri.path)
            end

            response.code.to_i == 200
          rescue StandardError
            false
          end

          def check_referer
            Decidim::Organization.exists?(["host ~ ?", request_host])
          end

          def request_host
            @request_host ||= URI.parse(request.base_url).host
          end
        end
      end
    end
  end
end
