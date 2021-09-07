# name: discourse-follow
# about: Discourse Follow
# version: 1.0
# authors: Angus McLeod, Robert Barrow
# url: https://github.com/paviliondev/discourse-follow

enabled_site_setting :discourse_follow_enabled

register_asset 'stylesheets/common/follow.scss'
register_asset 'stylesheets/mobile/follow.scss', :mobile

if respond_to?(:register_svg_icon)
  register_svg_icon "user-friends"
  register_svg_icon "user-check"
end

Discourse.top_menu_items.push(:following)
Discourse.anonymous_top_menu_items.push(:following)
Discourse.filters.push(:following)
Discourse.anonymous_filters.push(:following)

after_initialize do
  Notification.types[:following] = 800
  Notification.types[:following_posted] = 801
  Notification.types[:following_replied] = 802
  
  PostAlerter::NOTIFIABLE_TYPES.push(Notification.types[:following])
  PostAlerter::NOTIFIABLE_TYPES.push(Notification.types[:following_posted])
  PostAlerter::NOTIFIABLE_TYPES.push(Notification.types[:following_replied])
  PostAlerter::COLLAPSED_NOTIFICATION_TYPES.push(Notification.types[:following_replied])
  
  %w[
    ../lib/follow/engine.rb
    ../lib/follow/notification.rb
    ../lib/follow/updater.rb
    ../lib/follow/following_migration.rb
    ../app/controllers/follow/follow_controller.rb
    ../app/controllers/follow/follow_admin_controller.rb
    ../config/routes.rb
    ../app/models/user_destroyer_edits.rb
    ../app/models/post_alerter_edits.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  add_to_class(:user, :following_ids) do
    following.map { |f| f.first }
  end

  add_to_class(:user, :following_ids_first_post) do
    following.select { |f| ["3","4"].include?f[1] }.map { |f| f[0] }
  end

  add_to_class(:user, :following_ids_all_posts) do
    following.select { |f| f[1] == "3" }.map { |f| f[0] }
  end
  
  add_to_class(:user, :following) do
    if custom_fields['following']
      [*custom_fields['following']].map do |record|
        record.split(',')
      end
    else
      []
    end
  end
  
  add_to_class(:user, :followers) do
    if custom_fields['followers']
      custom_fields['followers'].split(',')
    else
      []
    end
  end
  
  add_to_class(:topic_query, :list_following) do
    create_list(:following) do |topics|
      topics.where("
        topics.id IN (
          SELECT topic_id FROM posts
          WHERE posts.user_id in (?)
          UNION SELECT topic_id FROM posts
          WHERE posts.user_id in (?)
          AND posts.post_number = 1
        )", @user.following_ids_all_posts, @user.following_ids_first_post)
    end
  end

  add_to_serializer(:current_user, :total_following) { object.following.length }

  add_to_serializer(:user, :include_following?) { scope.current_user }
  add_to_serializer(:user, :total_followers) { SiteSetting.discourse_follow_enabled ? object.followers.length : 0}
  add_to_serializer(:user, :include_total_followers?) { SiteSetting.follow_show_statistics_on_profile }
  add_to_serializer(:user, :total_following) { SiteSetting.discourse_follow_enabled ? object.following.length : 0}
  add_to_serializer(:user, :include_total_following?) { SiteSetting.follow_show_statistics_on_profile }
  add_to_serializer(:user, :can_see_following) { can_see_follow_type("following") }
  add_to_serializer(:user, :can_see_followers) { can_see_follow_type("followers") }
  add_to_serializer(:user, :can_see_follow) {
    can_see_following || can_see_followers
  }

  add_to_serializer(:user_card, :following_notification_level) {
    scope.current_user && SiteSetting.discourse_follow_enabled ?
      (following_entry = scope.current_user.following.find {|e| e[0] == object.id.to_s}) ? following_entry[1] : ""
      : ""
  }
  add_to_serializer(:user_card, :total_followers) { SiteSetting.discourse_follow_enabled ? object.followers.length : 0}
  add_to_serializer(:user_card, :total_following) { SiteSetting.discourse_follow_enabled ? object.following.length : 0}

  add_to_class(:user_serializer, :can_see_follow_type) do |type|
    allowed = SiteSetting.try("follow_#{type}_visible") || nil

    userInAllowedGroup = false

    if !['everyone', 'self', 'no-one'].include? allowed
      allowedGroup = Group.find_by(name: allowed)
      userInAllowedGroup = scope.current_user && allowedGroup && GroupUser.find_by(user_id: scope.current_user.id, group_id: allowedGroup.id)
    end

    allowed == 'everyone' || allowed != 'no-one' && scope.current_user && user.id == scope.current_user.id || userInAllowedGroup
  end
  
  %w[
    notify_me_when_followed
    notify_followed_user_when_followed
    notify_me_when_followed_replies
    notify_me_when_followed_posts
  ].each do |field|
    User.register_custom_field_type(field, :boolean)
    DiscoursePluginRegistry.serialized_current_user_fields << field
    # default options to true if not set by user
    add_to_class(:user, field.to_sym) do
      if custom_fields[field] != nil
        custom_fields[field]
      else
        true
      end
    end
    add_to_serializer(:user, field.to_sym)  {object.send(field)}
    register_editable_user_custom_field field.to_sym
  end
end

