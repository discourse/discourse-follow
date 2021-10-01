# frozen_string_literal: true

class UserFollower < ActiveRecord::Base
  def self.posts_for(user, current_user:, limit: nil, created_before: nil)
    visible_post_types = [Post.types[:regular]]
    visible_post_types << Post.types[:whisper] if current_user.staff?

    results = Post
      .joins(:topic, user: :followers, topic: :category)
      .preload(:user, topic: :category)
      .where(post_type: visible_post_types)
      .where("topics.archetype != ?", Archetype.private_message)
      .where("topics.visible")
      .where("user_followers.follower_id = ?", user.id)
      .order(created_at: :desc)

    results = Guardian.new(current_user).filter_allowed_categories(results)
    results = results.limit(limit) if limit
    results = results.where("posts.created_at < ?", created_before) if created_before

    results
  end

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
