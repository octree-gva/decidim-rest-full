# frozen_string_literal: true

Decidim::RestFull::Core::DefinitionRegistry.register_resource(:vote_proposal) do
  {
    type: :object,
    title: "Vote proposal",
    description: "A user's vote on a published proposal (Decidim::Proposals::ProposalVote).",
    properties: {
      id: { type: :string },
      type: { type: :string, enum: ["vote_proposals"] },
      attributes: {
        type: :object,
        properties: {
          weight: { type: :integer, description: "Vote weight (0 = abstention when enabled)" },
          created_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:creation_date) },
          updated_at: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:edition_date) }
        },
        required: %w(weight created_at updated_at),
        additionalProperties: false
      },
      relationships: {
        type: :object,
        properties: {
          proposal: {
            type: :object,
            properties: {
              data: {
                type: :object,
                properties: {
                  type: { type: :string, enum: ["proposals"] },
                  id: { type: :string }
                }
              }
            }
          },
          author: {
            type: :object,
            properties: {
              data: {
                type: :object,
                properties: {
                  type: { type: :string, enum: ["users"] },
                  id: { type: :string }
                }
              }
            }
          }
        }
      }
    },
    required: %w(id type)
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:vote_proposal_create_body) do
  {
    type: :object,
    required: %w(proposal_id data),
    properties: {
      proposal_id: { type: :integer, description: "Published proposal id" },
      data: {
        type: :object,
        required: [:weight],
        properties: {
          weight: { type: :integer, description: "Vote weight" }
        },
        additionalProperties: false
      }
    }
  }
end

Decidim::RestFull::Core::DefinitionRegistry.register_object(:vote_proposals_index_response) do
  {
    type: :object,
    properties: {
      data: {
        type: :array,
        items: { "$ref" => Decidim::RestFull::Core::DefinitionRegistry.reference(:vote_proposal) }
      },
      meta: {
        type: :object,
        properties: {
          page: { type: :integer },
          per_page: { type: :integer }
        }
      }
    }
  }
end
