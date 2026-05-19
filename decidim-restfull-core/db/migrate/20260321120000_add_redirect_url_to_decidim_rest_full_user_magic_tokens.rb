# frozen_string_literal: true

class AddRedirectUrlToDecidimRestFullUserMagicTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_rest_full_user_magic_tokens, :redirect_url, :string, limit: 2048
  end
end
