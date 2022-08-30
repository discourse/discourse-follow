# frozen_string_literal: true

class Follow::NotificationHandler
  attr_reader :post

  def initialize(post, notified_users)
    @post = post
    @notified_users = notified_users
  end

  def handle
    return if post.post_type == Post.types[:whisper] && post.action_code.present?
    return if [Post.types[:regular], Post.types[:whisper]].exclude?(post.post_type)
    return if !SiteSetting.follow_notifications_enabled
    return if !post.user.allow_people_to_follow_me
    return if post.user.user_option&.hide_profile_and_presence

    topic = post.topic
    return if !topic || topic.private_message?

    poster_followers.each do |follower|
      next if follower.bot? || follower.staged?
      next if topic_muted_by?(follower)

      if post.post_number == 1
        next if !follower.notify_me_when_followed_creates_topic
      else
        next if !follower.notify_me_when_followed_replies
      end

      guardian = Guardian.new(follower)
      next if !guardian.can_see?(post)

      if post.post_number == 1
        notification_type = Notification.types[:following_created_topic]
      else
        notification_type = Notification.types[:following_replied]
      end

      # sometimes the `post_alerter_after_save_post` event can be fired twice
      # for the same post resulting (incorrectly) in merged or double
      # notifications. skip if we've already created a notification for this
      # post
      next if already_notified?(follower, notification_type)

      # if the user has received a notification for the post because they're
      # watching the topic, category or a tag, then delete the notification so
      # they don't end up with double notifications.
      #
      # the `notified` array provided by the event includes users who are
      # notified due to a mention (directly or via a group), quote, link to a
      # post of theirs, or reply to them directly. It does not include users
      # who are notified because they're watching the topic, category or a tag.
      follower.notifications.where(
        topic_id: topic.id,
        notification_type: [
          Notification.types[:posted],
          Notification.types[:replied]
        ],
        post_number: post.post_number
      ).destroy_all

      # delete all existing follow notifications for the topic because we'll
      # collapse them
      follower.notifications.where(
        topic_id: topic.id,
        notification_type: [
          Notification.types[:following_replied],
          Notification.types[:following_created_topic]
        ]
      ).destroy_all

      posts_by_following = topic
        .posts
        .secured(guardian)
        .where(user_id: follower.following.pluck(:id))
        .where(<<~SQL, follower_id: follower.id, topic_id: topic.id)
          post_number > COALESCE((
            SELECT last_read_post_number FROM topic_users tu
            WHERE tu.user_id = :follower_id AND tu.topic_id = :topic_id
          ), 0)
        SQL

      count = posts_by_following.count
      first_unread_post = posts_by_following.order('post_number').first || post

      display_username = first_unread_post.user.username
      if count > 1
        I18n.with_locale(follower.effective_locale) do
          display_username = I18n.t('embed.replies', count: count)
        end
      end

      notification_data = {
        topic_title: topic.title,
        original_post_id: post.id,
        original_post_type: post.post_type,
        display_username: display_username
      }

      notification = follower.notifications.create!(
        notification_type: notification_type,
        topic_id: topic.id,
        post_number: first_unread_post.post_number,
        data: notification_data.to_json
      )
      @notified_users << follower

      if notification&.id && !follower.suspended?
        PostAlerter.create_notification_alert(
          user: follower,
          post: post,
          notification_type: notification_type
        )
      end
    end
  end

  private

  def topic_muted_by?(user)
    TopicUser.exists?(
      topic_id: post.topic.id,
      user_id: user.id,
      notification_level: TopicUser.notification_levels[:muted]
    )
  end

  def already_notified?(user, notification_type)
    Notification.exists?(
      topic_id: post.topic.id,
      user_id: user.id,
      notification_type: notification_type,
      post_number: post.post_number
    )
  end

  def poster_followers
    followers = post.user.followers
    if @notified_users.present?
      followers = followers.where("users.id NOT IN (?)", @notified_users.map(&:id))
    end
    followers
  end
end
