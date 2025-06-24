# frozen_string_literal: true

class AddIsEventToApiClientPermissions < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_rest_full_api_client_permissions, :is_event, :boolean, default: false, null: false
  end
end
