# frozen_string_literal: true

class CreateProposalApplicationId < ActiveRecord::Migration[7.0]
  def change
    create_table :proposal_application_ids do |t|
      t.references :proposal, null: false, foreign_key: { to_table: "decidim_proposals_proposals" }
      t.references :api_client, null: false, foreign_key: { to_table: "oauth_applications" }
      t.timestamps
    end
  end
end
