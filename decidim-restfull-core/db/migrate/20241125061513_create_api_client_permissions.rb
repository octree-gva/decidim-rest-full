# frozen_string_literal: true

class CreateApiClientPermissions < ActiveRecord::Migration[6.1]
  def change
    create_table :decidim_rest_full_api_client_permissions do |t|
      t.references :api_client, null: false, foreign_key: { to_table: "oauth_applications" }
      t.string :permission, null: false
      t.timestamps
    end
    add_index :decidim_rest_full_api_client_permissions, [:api_client_id, :permission], unique: true, name: "index_decidim_restfull_permissions"
  end
end
