# name: discourse-follow
# about: Discourse Follow
# version: 0.2
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-follow

enabled_site_setting :discourse_follow_enabled

register_asset 'stylesheets/common/follow.scss'
register_asset 'stylesheets/mobile/follow.scss', :mobile

if respond_to?(:register_svg_icon)
  register_svg_icon "user-friends"
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
    ../app/controllers/follow/follow_controller.rb
    ../config/routes.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  add_to_class(:user, :following_ids) do
    following.map { |f| f.first }
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
        )", @user.following_ids)
    end
  end
  
  add_to_serializer(:current_user, :total_following) { object.following.length }
  add_to_serializer(:user_card, :following) { scope.current_user ? object.followers.include?(scope.current_user.id.to_s) : "" }
  add_to_serializer(:user, :include_following?) { scope.current_user }
  add_to_serializer(:user, :total_followers) { object.followers.length }
  add_to_serializer(:user, :include_total_followers?) { SiteSetting.follow_show_statistics_on_profile }
  add_to_serializer(:user, :total_following) { object.following.length }
  add_to_serializer(:user, :include_total_following?) { SiteSetting.follow_show_statistics_on_profile }
  
  add_to_serializer(:user, :can_see_following) { can_see_follow_type("following") }
  add_to_serializer(:user, :can_see_followers) { can_see_follow_type("followers") }
  add_to_serializer(:user, :can_see_follow) {
    can_see_following || can_see_followers
  }
  
  add_to_class(:user_serializer, :can_see_follow_type) do |type|
    allowed = SiteSetting.try("follow_#{type}_visible") || nil
    (allowed == 'self' && scope.current_user && object.id == scope.current_user.id) || allowed == 'all'
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

  #### Non-Api Monkey patches
  
  ## User Destroyer
  ## There is no DiscourseEvent that fires before UserCustomFields are destroyed
  
  module UserDestroyerFollowerExtension
    protected def prepare_for_destroy(user)
      user.following_ids.each do |user_id|
        if following = User.find_by(id: user_id)
          updater = Follow::Updater.new(user, following)
          updater.update(false)
        end
      end
      user.followers.each do |user_id|
        if follower = User.find_by(id: user_id)
          updater = Follow::Updater.new(follower, user)
          updater.update(false)
        end
      end
      super(user)
    end
  end
  
  class ::UserDestroyer
    prepend UserDestroyerFollowerExtension
  end
  
  ## PostAlerter
  ## A number of overridden methods need to refer to the core method (i.e. super class)

  module PostAlerterFollowExtension
    def after_save_post(post, new_record = false)
      super(post, new_record)

      if new_record && !post.topic.private_message?
        notified = [*notified_users[post.id]]
        followers = SiteSetting.follow_notifications_enabled ? post.is_first_post? ? author_posted_followers(post) : author_replied_followers(post) : []
        type = post.is_first_post? ? :following_posted : :following_replied
        notify_users((followers || []) - notified, type, post)
      end
    end

    def author_posted_followers(post)
      User.find(post.user_id).followers.map do |user_id|
        User.find(user_id).notify_me_when_followed_posts ? User.find(user_id) : nil
      end.reject(&:nil?)
    end

    def author_replied_followers(post)
      User.find(post.user_id).followers.reduce([]) do |users, user_id|
        user = User.find(user_id).notify_me_when_followed_replies ? User.find(user_id) : nil
        following = user ? user.following.select { |data| data[0] == post.user_id } : nil
        if following && following.last.to_i == Follow::Notification.levels[:watching]
          users.push(user)
        end
      end
    end

    def notify_users(users, type, post, opts = {})
      users = super(users, type, post, opts = {})
      add_notified_users(users, post.id)
      users
    end

    def add_notified_users(users, post_id)
      new_users = [*users]
      current_users = notified_users[post_id] || []
      notified_users[post_id] = (new_users + current_users).uniq
    end

    def notified_users
      @notified_users ||= []
    end

    def create_notification(user, type, post, opts = {})
      @current_notification_type = type
      super(user, type, post, opts)
      @current_notification_type = nil
    end

    def unread_posts(user, topic)
      if @current_notification_type == Notification.types[:following_replied]
        posts = Post.secured(Guardian.new(user))
          .where('post_number > COALESCE((
                   SELECT last_read_post_number FROM topic_users tu
                   WHERE tu.user_id = ? AND tu.topic_id = ? ),0)',
                    user.id, topic.id)

        posts = posts
          .where("exists(
                SELECT 1 from user_custom_fields ucf
                WHERE ucf.user_id = ? AND
                  ucf.name = 'following' AND
                  split_part(ucf.value,',', 1)::integer = posts.user_id AND
                  split_part(ucf.value, ',', 2)::integer = ?
                )", user.id, Follow::Notification.levels[:watching])
          .where(topic_id: topic.id)
      else
        posts = super(user, topic)
      end

      posts
    end

    def first_unread_post(user, topic)
      unread_posts(user, topic).order('post_number').first
    end

    def unread_count(user, topic)
      unread_posts(user, topic).count
    end
  end

  require_dependency 'post_alerter'
  class ::PostAlerter
    prepend PostAlerterFollowExtension
  end
end
