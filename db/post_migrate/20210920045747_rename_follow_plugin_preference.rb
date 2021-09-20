# frozen_string_literal: true

class RenameFollowPluginPreference < ActiveRecord::Migration[6.1]
  def up
    DB.exec <<~SQL
      UPDATE user_custom_fields ucf
      SET name = 'notify_me_when_followed_creates_topic'
      WHERE ucf.name = 'notify_me_when_followed_posts'
    SQL
  end

  def down
    DB.exec <<~SQL
      UPDATE user_custom_fields ucf
      SET name = 'notify_me_when_followed_posts'
      WHERE ucf.name = 'notify_me_when_followed_creates_topic'
    SQL
  end
end
