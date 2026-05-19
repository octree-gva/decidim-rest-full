# frozen_string_literal: true

class CreateOrganizationExtendedData < ActiveRecord::Migration[7.0]
  def change
    create_table :organization_extended_data do |t|
      t.references :organization, null: false, foreign_key: { to_table: "decidim_organizations" }
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end
  end
end
