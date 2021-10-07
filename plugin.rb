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

register_svg_icon "discourse-follow-new-reply"
register_svg_icon "discourse-follow-new-follower"
register_svg_icon "discourse-follow-new-topic"

load File.expand_path('../lib/follow/engine.rb', __FILE__)

Discourse::Application.routes.append do
  mount ::Follow::Engine, at: "follow"
  %w{users u}.each_with_index do |root_path, index|
    get "#{root_path}/:username/follow" => "follow/follow#index", constraints: { username: RouteFormat.username }
    get "#{root_path}/:username/follow/feed" => "follow/follow#index", constraints: { username: RouteFormat.username }

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
    ../lib/follow/notification_handler.rb
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
    user_is_current_user || can_see_following || can_see_followers
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
    Follow::NotificationHandler.new(post, notified).handle
  end
end
