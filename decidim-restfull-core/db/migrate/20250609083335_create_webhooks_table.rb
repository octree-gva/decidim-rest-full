# frozen_string_literal: true

class CreateWebhooksTable < ActiveRecord::Migration[7.0]
  def change
    create_table :webhooks_tables do |t|
      t.string :private_key, null: false
      t.string :url, null: false
      t.jsonb :subscriptions, null: false, default: []
      t.references :api_client, null: false, foreign_key: { to_table: "oauth_applications" }

      t.timestamps
    end

    add_index :webhooks_tables, [:url, :api_client_id], unique: true
  end
end
