# frozen_string_literal: true

class AddOrgStatusIndexToRestFullApiJobs < ActiveRecord::Migration[7.0]
  def change
    add_index :decidim_rest_full_api_jobs,
              [:decidim_organization_id, :status],
              name: "index_rest_full_api_jobs_on_org_and_status"
  end
end
