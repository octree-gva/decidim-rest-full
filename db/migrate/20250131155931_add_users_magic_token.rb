# frozen_string_literal: true

class AddUsersMagicToken < ActiveRecord::Migration[7.0]
  def change
    create_table :decidim_rest_full_user_magic_tokens do |t|
      t.references :user, null: false, foreign_key: { to_table: "decidim_users" }
      t.string :magic_token, null: false
      t.datetime :expires_at, :datetime
      t.timestamps
    end
    add_index :decidim_rest_full_user_magic_tokens, :user_id, unique: true, name: "uniq_decidim_restfull_magic_usr"
    add_index :decidim_rest_full_user_magic_tokens, :magic_token, unique: true, name: "uniq_decidim_restfull_magic_token"
  end
end
