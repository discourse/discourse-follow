# frozen_string_literal: true

# name: discourse-follow
# about: Allows users to follow other users, list the latest topics involving them, and receive notifications when they post.
# meta_topic_id: 110579
# version: 1.0
# authors: Angus McLeod, Robert Barrow, CDCK Inc
# url: https://github.com/discourse/discourse-follow

enabled_site_setting :discourse_follow_enabled

register_asset "stylesheets/common/follow.scss"

register_svg_icon "discourse-follow-new-reply"
register_svg_icon "discourse-follow-new-follower"
register_svg_icon "discourse-follow-new-topic"

module ::Follow
  PLUGIN_NAME = "discourse-follow"
end

require_relative "lib/follow/engine"

after_initialize do
  Notification.types[:following] = 800
  Notification.types[:following_created_topic] = 801
  Notification.types[:following_replied] = 802

  reloadable_patch { |plugin| User.prepend(Follow::UserExtension) }

  add_to_serializer(:user, :can_see_following) do
    FollowPagesVisibility.can_see_following_page?(user: scope.current_user, target_user: user)
  end
  add_to_serializer(:user, :can_see_followers) do
    FollowPagesVisibility.can_see_followers_page?(user: scope.current_user, target_user: user)
  end
  add_to_serializer(:user, :can_see_network_tab) do
    user_is_current_user || can_see_following || can_see_followers
  end

  # UserSerializer in core inherits from UserCardSerializer.
  # we don't need to duplicate these attrs for UserSerializer.
  #
  # the `!options.key?(:each_serializer)` check is a temporary hack to exclude
  # the attributes we add here from the user card serializer when multiple user
  # objects are being serialized (e.g. the /user-cards.json route in core). If
  # we don't do this, we end up introducing a horrible 3N+1 on the
  # /user-cards.json route and it's not easily fixable.
  # when serializing a single user object, the options of the serializer
  # doesn't have a `each_serializer` key.
  add_to_serializer(:user_card, :can_follow) do
    !options.key?(:each_serializer) && scope.current_user.present? && user.allow_people_to_follow_me
  end

  add_to_serializer(:user_card, :is_followed) do
    !options.key?(:each_serializer) && scope.current_user.present? &&
      scope.current_user.following.where(id: user.id).exists?
  end

  add_to_serializer(
    :user_card,
    :total_followers,
    include_condition: -> do
      !options.key?(:each_serializer) && SiteSetting.discourse_follow_enabled &&
        SiteSetting.follow_show_statistics_on_profile &&
        FollowPagesVisibility.can_see_followers_page?(user: scope.current_user, target_user: object)
    end,
  ) { object.followers.count }

  add_to_serializer(
    :user_card,
    :total_following,
    include_condition: -> do
      !options.key?(:each_serializer) && SiteSetting.discourse_follow_enabled &&
        SiteSetting.follow_show_statistics_on_profile &&
        FollowPagesVisibility.can_see_following_page?(user: scope.current_user, target_user: object)
    end,
  ) { object.following.count }

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

  on(:post_alerter_before_post) do |post, new_record, notified|
    Follow::NotificationHandler.new(post, notified).handle if new_record
  end

  # TODO(2022-08-30): Remove when post_alerter_before_post is available
  on(:post_alerter_after_save_post) do |post, new_record, notified|
    next if !new_record
    Follow::NotificationHandler.new(post, notified).handle
  end

  filter_following_topics = ->(scope, username, guardian) do
    user = User.find_by(username: username)

    next scope if user.nil?
    next scope.none if user.id != guardian.user.id && !guardian.user.staff?

    topic_ids = UserFollower.posts_for(user, current_user: guardian.user).map { |p| p.topic_id }
    scope.where("topics.id IN (?)", topic_ids)
  end

  add_filter_custom_filter("following-feed", &filter_following_topics)
end
