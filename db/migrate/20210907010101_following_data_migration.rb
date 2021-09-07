class FollowingDataMigration < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      UPDATE user_custom_fields
      SET value = REPLACE(value,',0',',3')
      WHERE name = 'following'
    SQL
    execute <<~SQL
      UPDATE user_custom_fields 
      SET value = REPLACE(value,',1',',4')
      WHERE name = 'following'
    SQL
  end
  def down
    execute <<~SQL
      UPDATE user_custom_fields
      SET value = REPLACE(value,',3',',0')
      WHERE name = 'following'
    SQL

    execute <<~SQL
      UPDATE user_custom_fields
      SET value = REPLACE(value,',4',',1')
      WHERE name = 'following'
    SQL
  end
end