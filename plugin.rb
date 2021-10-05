# frozen_string_literal: true

# name: discourse-follow
# about: Discourse Follow
# version: 1.0
# authors: Angus McLeod, Robert Barrow, CDCK Inc
# url: https://github.com/paviliondev/discourse-follow
# transpile_js: true

enabled_site_setting :discourse_follow_enabled

register_asset 'stylesheets/common/follow.scss'
register_asset 'stylesheets/mobile/follow.scss', :mobile

if respond_to?(:register_svg_icon)
  register_svg_icon "user-friends"
  register_svg_icon "user-check"
end

load File.expand_path('../lib/follow/engine.rb', __FILE__)

Discourse::Application.routes.append do
  mount ::Follow::Engine, at: "follow"
  %w{users u}.each_with_index do |root_path, index|
    get "#{root_path}/:username/follow" => "follow/follow#index", constraints: { username: RouteFormat.username }
    get "#{root_path}/:username/follow/following" => "follow/follow#list_following", constraints: { username: RouteFormat.username }
    get "#{root_path}/:username/follow/followers" => "follow/follow#list_followers", constraints: { username: RouteFormat.username }
  end
end

after_initialize do
  Notification.types[:following] = 800
  Notification.types[:following_created_topic] = 801
  Notification.types[:following_replied] = 802

  %w[
    ../lib/follow/notification.rb
    ../lib/follow/updater.rb
    ../lib/follow/user_extension.rb
    ../app/controllers/follow/follow_controller.rb
    ../config/routes.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  reloadable_patch do |plugin|
    User.class_eval { prepend Follow::UserExtension }
  end

  add_to_serializer(:user, :can_see_following) do
    FollowPagesVisibility.can_see_following_page?(user: scope.current_user, target_user: user)
  end
  add_to_serializer(:user, :can_see_followers) do
    FollowPagesVisibility.can_see_followers_page?(user: scope.current_user, target_user: user)
  end
  add_to_serializer(:user, :can_see_network_tab) do
    can_see_following || can_see_followers
  end

  # UserSerializer in core inherits from UserCardSerializer.
  # we don't need to duplicate these attrs for UserSerializer
  add_to_serializer(:user_card, :can_follow) do
    scope.current_user.present? && user.allow_people_to_follow_me
  end

  add_to_serializer(:user_card, :is_followed) do
    scope.current_user.present? && scope.current_user.following.where(id: user.id).exists?
  end

  add_to_serializer(:user_card, :total_followers, false) do
    object.followers.count
  end
  add_to_serializer(:user_card, :include_total_followers?) do
    SiteSetting.discourse_follow_enabled &&
      SiteSetting.follow_show_statistics_on_profile &&
      FollowPagesVisibility.can_see_followers_page?(user: scope.current_user, target_user: object)
  end

  add_to_serializer(:user_card, :total_following, false) do
    object.following.count
  end
  add_to_serializer(:user_card, :include_total_following?) do
    SiteSetting.discourse_follow_enabled &&
      SiteSetting.follow_show_statistics_on_profile &&
      FollowPagesVisibility.can_see_following_page?(user: scope.current_user, target_user: object)
  end

  %i[
    notify_me_when_followed
    notify_followed_user_when_followed
    notify_me_when_followed_replies
    notify_me_when_followed_creates_topic
    allow_people_to_follow_me
  ].each do |field|
    add_to_class(:user, field) do
      v = custom_fields[field]
      if !v.nil?
        HasCustomFields::Helpers::CUSTOM_FIELD_TRUE.include?(v.to_s.downcase)
      else
        SiteSetting.public_send(:"default_#{field}")
      end
    end

    User.register_custom_field_type(field, :boolean)
    DiscoursePluginRegistry.serialized_current_user_fields << field
    add_to_serializer(:user, field) { object.public_send(field) }
    register_editable_user_custom_field(field)
  end

  on(:post_alerter_after_save_post) do |post, new_record, notified|
    next if !new_record
    next if post.post_type == Post.types[:whisper] && post.action_code.present?
    next if [Post.types[:regular], Post.types[:whisper]].exclude?(post.post_type)
    next if !SiteSetting.follow_notifications_enabled
    next if !post.user.allow_people_to_follow_me
    topic = post.topic
    next if !topic || topic.private_message?
    followers = post.user.followers
    followers = followers.where("users.id NOT IN (?)", notified.map(&:id)) if notified.present?
    followers.each do |f|
      next if f.bot? || f.staged?
      next if TopicUser.where(
        topic_id: topic.id,
        user_id: f.id,
        notification_level: TopicUser.notification_levels[:muted]
      ).exists?

      if post.post_number == 1
        next if !f.notify_me_when_followed_creates_topic
      else
        next if !f.notify_me_when_followed_replies
      end

      guardian = Guardian.new(f)
      next if !guardian.can_see?(post)

      # if the user has received a notification for the post because they're
      # watching the topic, category or a tag, then delete the notification so
      # they don't end up with double notifications.
      #
      # the `notified` array provided by the event includes users who are
      # notified due to a mention (directly or via a group), quote, link to a
      # post of theirs, or reply to them directly. It does not include users
      # who are notified because they're watching the topic, category or a tag.
      f.notifications.where(
        topic_id: topic.id,
        notification_type: [
          Notification.types[:posted],
          Notification.types[:replied]
        ],
        post_number: post.post_number
      ).destroy_all

      # delete all existing follow notifications for the topic because we'll
      # collapse them
      f.notifications.where(
        topic_id: topic.id,
        notification_type: [
          Notification.types[:following_replied],
          Notification.types[:following_created_topic]
        ]
      ).destroy_all

      posts_by_following = topic
        .posts
        .secured(guardian)
        .where(user_id: f.following.pluck(:id))
        .where(<<~SQL, follower_id: f.id, topic_id: topic.id)
          post_number > COALESCE((
            SELECT last_read_post_number FROM topic_users tu
            WHERE tu.user_id = :follower_id AND tu.topic_id = :topic_id
          ), 0)
        SQL

      if post.post_number == 1
        notification_type = Notification.types[:following_created_topic]
      else
        notification_type = Notification.types[:following_replied]
      end

      count = posts_by_following.count
      original_post = post
      post = posts_by_following.order('post_number').first || post

      begin
        orig_logster_env = Thread.current[Logster::Logger::LOGSTER_ENV]
        new_env = orig_logster_env.dup || {}
        new_env.merge!(
          follower_ids: followers.pluck(:id).inspect,
          topic_id: topic.id,
          post_user_id: post.user.id,
          follower_id: f.id,
          post_id: post.id,
          post_number: post.post_number,
          notified_size: notified&.size.inspect,
          notified_ids: notified&.map(&:id).inspect,
          original_post_id: original_post.id,
          original_post_number: original_post.post_number,
          count: count,
          sql_query: posts_by_following.to_sql
        )
        Thread.current[Logster::Logger::LOGSTER_ENV] = new_env
        Rails.logger.warn("[osama-debug-follow-plugin] notification from topic #{topic.id} to user #{f.id}")
      ensure
        Thread.current[Logster::Logger::LOGSTER_ENV] = orig_logster_env
      end

      display_username = post.user.username
      if count > 1
        I18n.with_locale(f.effective_locale) do
          display_username = I18n.t('embed.replies', count: count)
        end
      end
      notification_data = {
        topic_title: topic.title,
        original_post_id: original_post.id,
        original_post_type: original_post.post_type,
        display_username: display_username
      }

      notification = f.notifications.create!(
        notification_type: notification_type,
        topic_id: topic.id,
        post_number: post.post_number,
        data: notification_data.to_json
      )
      if notification&.id && !f.suspended?
        PostAlerter.create_notification_alert(
          user: f,
          post: original_post,
          notification_type: notification_type
        )
      end
    end
  end
end
