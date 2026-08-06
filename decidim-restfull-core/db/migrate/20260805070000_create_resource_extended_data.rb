# frozen_string_literal: true

class CreateResourceExtendedData < ActiveRecord::Migration[7.0]
  def up
    create_table :resource_extended_data do |t|
      t.string :resource_type, null: false
      t.bigint :resource_id, null: false
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end

    add_index :resource_extended_data,
              [:resource_type, :resource_id],
              unique: true,
              name: "index_resource_extended_data_on_resource"

    return unless table_exists?(:organization_extended_data)

    execute <<~SQL.squish
      INSERT INTO resource_extended_data (resource_type, resource_id, data, created_at, updated_at)
      SELECT 'Decidim::Organization', organization_id, data, created_at, updated_at
      FROM organization_extended_data
    SQL

    drop_table :organization_extended_data
  end

  def down
    create_table :organization_extended_data do |t|
      t.references :organization, null: false, foreign_key: { to_table: "decidim_organizations" }
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end

    execute <<~SQL.squish
      INSERT INTO organization_extended_data (organization_id, data, created_at, updated_at)
      SELECT resource_id, data, created_at, updated_at
      FROM resource_extended_data
      WHERE resource_type = 'Decidim::Organization'
    SQL

    drop_table :resource_extended_data
  end
end
