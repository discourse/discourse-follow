class FollowingDataMigration < ActiveRecord::Migration[5.2]
  def up
    execute "UPDATE user_custom_fields SET value = REPLACE(value,',0',',3') WHERE name = 'following'"
    execute "UPDATE user_custom_fields SET value = REPLACE(value,',1',',4') WHERE name = 'following'"
  end
  def down
    execute "UPDATE user_custom_fields SET value = REPLACE(value,',3',',0') WHERE name = 'following'"
    execute "UPDATE user_custom_fields SET value = REPLACE(value,',4',',1') WHERE name = 'following'"
  end
end