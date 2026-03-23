# frozen_string_literal: true

module Decidim
  module RestFull
    module Comment
      # Registers Ransack ransackers for Comment and CommentVote (decidim_component_id).
      module CommentRansackers
        module_function

        def register!
          register_comment_component_id!
          register_comment_vote_component_id!
        end

        def register_comment_component_id!
          Decidim::Comments::Comment.ransacker :decidim_component_id do
            Arel.sql(component_id_sql_for_comments_table("decidim_comments_comments"))
          end
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
          nil
        end

        def register_comment_vote_component_id!
          Decidim::Comments::CommentVote.ransacker :decidim_component_id do
            Arel.sql(<<~SQL.squish)
              (
                SELECT #{component_id_sql_for_comments_table("c")}
                FROM decidim_comments_comments AS c
                WHERE c.id = decidim_comments_comment_votes.decidim_comment_id
                LIMIT 1
              )
            SQL
          end
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
          nil
        end

        # SQL expression returning component id for one row of decidim_comments_comments (alias +table+).
        def component_id_sql_for_comments_table(table)
          root_cases = component_id_from_polymorphic_root("decidim_root_commentable_id", "decidim_root_commentable_type", table)
          direct_cases = component_id_from_polymorphic("decidim_commentable_id", "decidim_commentable_type", table)
          <<~SQL.squish
            CASE
              WHEN #{table}.decidim_commentable_type = 'Decidim::Comments::Comment' THEN (#{root_cases})
              ELSE (#{direct_cases})
            END
          SQL
        end

        def component_id_from_polymorphic(id_col, type_col, table)
          fragments = commentable_component_sql_fragments.map do |type, sql|
            <<~SQL.squish
              WHEN #{table}.#{type_col} = '#{type}' THEN (#{sql.gsub("{{ID}}", "#{table}.#{id_col}")})
            SQL
          end
          <<~SQL.squish
            CASE
              #{fragments.join("\n")}
              ELSE NULL
            END
          SQL
        end

        def component_id_from_polymorphic_root(id_col, type_col, table)
          component_id_from_polymorphic(id_col, type_col, table)
        end

        # [model name, subquery selecting decidim_component_id WHERE id = {{ID}}]
        def commentable_component_sql_fragments
          @commentable_component_sql_fragments ||= build_commentable_component_sql_fragments
        end

        def build_commentable_component_sql_fragments
          # Static map so SQL is available without DB at first load (OpenAPI / assets).
          # Budgets::Project has no direct component id — resolve via budget.
          {
            "Decidim::Proposals::Proposal" => "SELECT decidim_component_id FROM decidim_proposals_proposals WHERE id = {{ID}} LIMIT 1",
            "Decidim::Meetings::Meeting" => "SELECT decidim_component_id FROM decidim_meetings_meetings WHERE id = {{ID}} LIMIT 1",
            "Decidim::Blogs::Post" => "SELECT decidim_component_id FROM decidim_blogs_posts WHERE id = {{ID}} LIMIT 1",
            "Decidim::Debates::Debate" => "SELECT decidim_component_id FROM decidim_debates_debates WHERE id = {{ID}} LIMIT 1",
            "Decidim::Budgets::Project" => <<~SQL.squish,
              SELECT b.decidim_component_id
              FROM decidim_budgets_projects p
              INNER JOIN decidim_budgets_budgets b ON b.id = p.decidim_budgets_budget_id
              WHERE p.id = {{ID}} LIMIT 1
            SQL
            "Decidim::Accountability::Result" => "SELECT decidim_component_id FROM decidim_accountability_results WHERE id = {{ID}} LIMIT 1",
            "Decidim::Sortitions::Sortition" => "SELECT decidim_component_id FROM decidim_sortitions_sortitions WHERE id = {{ID}} LIMIT 1"
          }.map { |type, sql| [type, sql] }
        end
      end
    end
  end
end
