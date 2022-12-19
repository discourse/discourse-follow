# frozen_string_literal: true

class CorrectFollowPluginSiteSettingValues < ActiveRecord::Migration[6.1]
  def up
    DB.exec(<<~SQL)
      UPDATE site_settings
      SET value = 'no-one'
      WHERE name IN ('follow_followers_visible', 'follow_following_visible') AND value = 'none'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
