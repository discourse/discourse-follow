# frozen_string_literal: true

class CreateUserFollower < ActiveRecord::Migration[6.1]
  def change
    create_table :user_followers do |t|
      t.bigint :user_id, null: false
      t.bigint :follower_id, null: false
      t.integer :level, null: false

      t.timestamps null: false
    end

    add_index :user_followers, %i(user_id follower_id), unique: true
  end
end
