# frozen_string_literal: true

class RemovePollSecretFromDecidimRestFullApiJobs < ActiveRecord::Migration[7.0]
  def change
    remove_column :decidim_rest_full_api_jobs, :poll_secret, :string
  end
end
