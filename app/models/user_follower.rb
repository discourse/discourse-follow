# frozen_string_literal: true

class UserFollower < ActiveRecord::Base
  belongs_to :follower_user, class_name: 'User', foreign_key: :follower_id
  belongs_to :followed_user, class_name: 'User', foreign_key: :user_id
end

# == Schema Information
#
# Table name: user_followers
#
#  id          :bigint           not null, primary key
#  user_id     :bigint           not null
#  follower_id :bigint           not null
#  level       :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_user_followers_on_user_id_and_follower_id  (user_id,follower_id) UNIQUE
#
