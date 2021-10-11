# frozen_string_literal: true

class MigrateFollowerDataFromCustomFieldsToTables < ActiveRecord::Migration[6.1]
  def up
    DB.exec <<~SQL
      INSERT INTO user_followers (follower_id, user_id, level, updated_at, created_at) (
        SELECT
          user_id::bigint AS follower_id,
          split_part(value, ',', 1)::bigint AS user_id,
          (
            CASE
              WHEN split_part(value, ',', 2)::integer = 0 THEN 3
              WHEN split_part(value, ',', 2)::integer = 1 THEN 4
              ELSE split_part(value, ',', 2)::integer
            END
          ) AS level,
          updated_at,
          created_at
        FROM user_custom_fields
        WHERE name = 'following' AND TRIM(value) != '' AND user_id >= 1
      )
      ON CONFLICT DO NOTHING
    SQL

    DB.exec <<~SQL
      DELETE FROM user_custom_fields WHERE name = 'following' OR name = 'followers'
    SQL
  end

  def down
    DB.exec <<~SQL
      INSERT INTO user_custom_fields (user_id, name, value, created_at, updated_at) (
        SELECT
          follower_id::integer AS user_id,
          'following' AS name,
          user_id::text || ',' || level::text AS value,
          created_at,
          updated_at
        FROM user_followers
      )
    SQL

    DB.exec <<~SQL
      INSERT INTO user_custom_fields (user_id, name, value, created_at, updated_at) (
        SELECT
          user_id::integer AS user_id,
          'followers' AS name,
          ARRAY_TO_STRING(ARRAY_AGG(follower_id), ',') AS value,
          CURRENT_TIMESTAMP AS created_at,
          CURRENT_TIMESTAMP AS updated_at
        FROM user_followers
        GROUP BY user_id
      )
    SQL

    DB.exec("DELETE FROM user_followers")
  end
end
