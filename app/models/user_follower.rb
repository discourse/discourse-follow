# frozen_string_literal: true

class UserFollower < ActiveRecord::Base
  def self.posts_for(user, current_user:, limit: nil, created_before: nil)
    visible_post_types = [Post.types[:regular], Post.types[:moderator_action]]
    visible_post_types << Post.types[:whisper] if current_user.staff?

    results = Post
      .joins(:topic, :user, topic: :category)
      .joins("INNER JOIN user_followers ON user_followers.user_id = users.id")
      .preload(:user, topic: :category)
      .where(post_type: visible_post_types)
      .where("topics.archetype != ?", Archetype.private_message)
      .where("topics.visible")
      .where("user_followers.follower_id = ?", user.id)
      .where(action_code: nil)
      .order(created_at: :desc)

    results = filter_opted_out_users(results)
    results = Guardian.new(current_user).filter_allowed_categories(results)
    results = results.limit(limit) if limit
    results = results.where("posts.created_at < ?", created_before) if created_before

    results
  end

  def self.filter_opted_out_users(relation)
    truthy_values = sanitize_sql(["?", HasCustomFields::Helpers::CUSTOM_FIELD_TRUE])
    if SiteSetting.default_allow_people_to_follow_me
      relation = relation.joins(<<~SQL)
        LEFT OUTER JOIN user_custom_fields ucf
        ON ucf.name = 'allow_people_to_follow_me'
          AND ucf.user_id = users.id
          AND ucf.value NOT IN (#{truthy_values})
      SQL
      relation = relation.where("ucf.user_id IS NULL")
    else
      relation = relation.joins(<<~SQL)
        INNER JOIN user_custom_fields ucf
        ON ucf.name = 'allow_people_to_follow_me'
          AND ucf.user_id = users.id
          AND ucf.value IN (#{truthy_values})
      SQL
    end
    relation
      .joins("LEFT OUTER JOIN user_options uo ON uo.user_id = users.id")
      .where("uo.user_id IS NULL OR NOT uo.hide_profile_and_presence")
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
