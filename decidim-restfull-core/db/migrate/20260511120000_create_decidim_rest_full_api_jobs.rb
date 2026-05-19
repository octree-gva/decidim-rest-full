# frozen_string_literal: true

class CreateDecidimRestFullApiJobs < ActiveRecord::Migration[7.0]
  def change
    create_table :decidim_rest_full_api_jobs, id: :uuid do |t|
      t.references :decidim_organization, null: false, foreign_key: { to_table: :decidim_organizations }, index: true
      t.bigint :doorkeeper_access_token_id, null: false
      t.string :command_key, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :payload, null: false, default: {}
      t.jsonb :result, default: {}
      t.string :error_class
      t.text :error_message

      t.timestamps
    end

    add_index :decidim_rest_full_api_jobs, :doorkeeper_access_token_id
    add_index :decidim_rest_full_api_jobs, :status
    add_index :decidim_rest_full_api_jobs, :command_key
    add_foreign_key :decidim_rest_full_api_jobs, :oauth_access_tokens, column: :doorkeeper_access_token_id
  end
end
