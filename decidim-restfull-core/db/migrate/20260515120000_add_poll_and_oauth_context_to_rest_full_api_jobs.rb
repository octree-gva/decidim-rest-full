# frozen_string_literal: true

class AddPollAndOAuthContextToRestFullApiJobs < ActiveRecord::Migration[7.0]
  def up
    add_column :decidim_rest_full_api_jobs, :oauth_application_id, :bigint
    add_column :decidim_rest_full_api_jobs, :resource_owner_id, :bigint
    add_column :decidim_rest_full_api_jobs, :poll_secret, :string

    Decidim::RestFull::ApiJob.reset_column_information
    Decidim::RestFull::ApiJob.find_each do |job|
      token = Doorkeeper::AccessToken.find_by(id: job.doorkeeper_access_token_id)
      next unless token

      # rubocop:disable Rails/SkipsModelValidations -- backfill existing rows without callbacks
      job.update_columns(
        oauth_application_id: token.application_id,
        resource_owner_id: token.resource_owner_id,
        poll_secret: SecureRandom.urlsafe_base64(32)
      )
      # rubocop:enable Rails/SkipsModelValidations
    end

    change_column_null :decidim_rest_full_api_jobs, :oauth_application_id, false
    change_column_null :decidim_rest_full_api_jobs, :poll_secret, false

    add_index :decidim_rest_full_api_jobs, :oauth_application_id
    add_index :decidim_rest_full_api_jobs, :resource_owner_id
  end

  def down
    remove_index :decidim_rest_full_api_jobs, :resource_owner_id
    remove_index :decidim_rest_full_api_jobs, :oauth_application_id

    remove_column :decidim_rest_full_api_jobs, :poll_secret
    remove_column :decidim_rest_full_api_jobs, :resource_owner_id
    remove_column :decidim_rest_full_api_jobs, :oauth_application_id
  end
end
