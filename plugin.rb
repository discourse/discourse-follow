# name: discourse-follow
# about: Discourse Follow
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-follow

enabled_site_setting :discourse_follow_enabled

register_asset 'stylesheets/common/follow.scss'

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

  module ::Follow
    class Engine < ::Rails::Engine
      engine_name "follow"
      isolate_namespace Follow
    end
  end

  class ::User
    def following_ids
      following.map { |f| f.first }
    end

    def following
      if custom_fields['following']
        [*custom_fields['following']].map do |record|
          record.split(',')
        end
      else
        []
      end
    end

    def followers
      if custom_fields['followers']
        custom_fields['followers'].split(',')
      else
        []
      end
    end
  end

  class Follow::FollowController < ApplicationController
    def index
    end

    def update
      params.require(:username)
      params.require(:follow)

      raise Discourse::InvalidAccess.new unless current_user
      raise Discourse::InvalidParameters.new if current_user.username == params[:username]

      if user = User.find_by(username: params[:username])
        Follow::Helper.update(current_user, user, params[:follow])

        following = user.followers.include?(current_user.id.to_s)

        render json: success_json.merge(following: following)
      else
        render json: failed_json
      end
    end

    def list
      params.require(:type)

      user = User.where('lower(username) = ?', params[:username].downcase).first

      raise Discourse::InvalidParameters.new unless user.present?

      serializer = nil

      method = params[:type] == 'following' ? 'following_ids' : 'followers'
      users = user.send(method).map { |user_id| User.find(user_id) }

      serializer = ActiveModel::ArraySerializer.new(users, each_serializer: BasicUserSerializer)

      render json: MultiJson.dump(serializer)
    end
  end

  Discourse::Application.routes.append do
    mount ::Follow::Engine, at: "follow"
    %w{users u}.each_with_index do |root_path, index|
      get "#{root_path}/:username/follow" => "follow/follow#index", constraints: { username: RouteFormat.username }
      get "#{root_path}/:username/follow/following" => "follow/follow#list", constraints: { username: RouteFormat.username }
      get "#{root_path}/:username/follow/followers" => "follow/follow#list", constraints: { username: RouteFormat.username }
    end
  end

  Follow::Engine.routes.draw do
    put ":username" => "follow#update", constraints: { username: RouteFormat.username, format: /(json|html)/ }, defaults: { format: :json }
  end

  require_dependency 'topic_query'
  class ::TopicQuery
    def list_following
      create_list(:following) do |topics|
        topics.where("
          topics.id IN (
            SELECT topic_id FROM posts
            WHERE posts.user_id in (?)
          )", @user.following_ids)
      end
    end
  end

  class Follow::Notification
    def self.levels
      @levels ||= Enum.new(
        watching: 0,
        watching_first_post: 1
      )
    end
  end

  class Follow::Helper
    def self.update(user, target, follow)
      follow = ActiveModel::Type::Boolean.new.cast(follow)
      notification_level = Follow::Notification.levels[:watching]
      followers = target.followers
      following = user.following
      following_ids = user.following_ids

      if follow
        followers.push(user.id) if followers.exclude?(user.id.to_s)

        if following_ids.include?(target.id.to_s)
          following.each do |f|
            if f[0] == target.id.to_s
              f[1] = notification_level
            end
          end
        else
          following.push([target.id, notification_level])
        end
      else
        followers.delete(user.id.to_s)
        following = following.select { |f| f[0] != target.id.to_s }
      end

      target.custom_fields['followers'] = followers.join(',')
      user.custom_fields['following'] = following.map { |f| f.join(',') }

      target.save_custom_fields(true)
      user.save_custom_fields(true)

      if follow
        target.notifications.create!(
          notification_type: Notification.types[:following],
          data: {
            display_username: user.username,
            following: true
          }.to_json
        )
      end
    end
  end

  module PostAlerterFollowExtension
    def after_save_post(post, new_record = false)
      super(post, new_record)

      if new_record && !post.topic.private_message?
        notified = [*notified_users[post.id]]
        followers = post.is_first_post? ? author_posted_followers(post) : author_replied_followers(post)
        type = post.is_first_post? ? :following_posted : :following_replied
        notify_users(followers - notified, type, post)
      end
    end

    def author_posted_followers(post)
      User.find(post.user_id).followers.map do |user_id|
        User.find(user_id)
      end
    end

    def author_replied_followers(post)
      User.find(post.user_id).followers.reduce([]) do |users, user_id|
        user = User.find(user_id)
        following = user.following.select { |data| data[0] == post.user_id }
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

  PostAlerter::COLLAPSED_NOTIFICATION_TYPES.push(Notification.types[:following_replied])

  require_dependency 'post_alerter'
  class ::PostAlerter
    prepend PostAlerterFollowExtension
  end

  add_to_serializer(:current_user, :total_following) { object.following.length }

  add_to_serializer(:user, :following) { object.followers.include?(scope.current_user.id.to_s) }
  add_to_serializer(:user, :include_following?) { scope.current_user }
  add_to_serializer(:user, :total_followers) { object.followers.length }
  add_to_serializer(:user, :include_total_followers?) { SiteSetting.follow_show_statistics_on_profile }
  add_to_serializer(:user, :total_following) { object.following.length }
  add_to_serializer(:user, :include_total_following?) { SiteSetting.follow_show_statistics_on_profile }
end
