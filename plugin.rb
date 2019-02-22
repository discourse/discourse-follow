# name: discourse-follow
# about: Discourse Follow
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-follow

enabled_site_setting :discourse_follow_enabled

register_asset 'stylesheets/common/follow.scss'

if respond_to?(:register_svg_icon)
  register_svg_icon "user-minus"
end

Discourse.top_menu_items.push(:following)
Discourse.anonymous_top_menu_items.push(:following)
Discourse.filters.push(:following)
Discourse.anonymous_filters.push(:following)

after_initialize do
  Notification.types[:following] = 800

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
        notification_level = Follow::Notification.levels[:watching]
        followers = user.followers
        following = current_user.following
        following_ids = current_user.following_ids

        if ActiveModel::Type::Boolean.new.cast(params[:follow])
          followers.push(current_user.id) if followers.exclude?(current_user.id.to_s)

          if following_ids.include?(user.id.to_s)
            following.each do |f|
              if f[0] == user.id.to_s
                f[1] = notification_level
              end
            end
          else
            following.push([user.id, notification_level])
          end
        else
          followers.delete(current_user.id.to_s)
          following = following.select { |f| f[0] != user.id.to_s }
        end

        user.custom_fields['followers'] = followers.join(',')
        current_user.custom_fields['following'] = following.map { |f| f.join(',') }

        user.save_custom_fields(true)
        current_user.save_custom_fields(true)

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
      get "#{root_path}/:username/follow" => "follow/follow#index"
      get "#{root_path}/:username/follow/following" => "follow/follow#list"
      get "#{root_path}/:username/follow/followers" => "follow/follow#list"
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
        watching: 0
      )
    end

    def self.add_notified_users(users, post_id)
      notified_users[post_id] = users
    end

    def self.notified_users
      @notified_users || []
    end
  end

  DiscourseEvent.on(:before_create_notifications_for_users) do |users, post|
    Follow::Notification.add_notified_users(users, post.id)
  end

  module PostAlerterFollowExtension
    def after_save_post(post, new_record = false)
      super(post, new_record)

      if new_record
        followers = author_followers(post)
        notified = [*Follow::Notification.notified_users[post.id]]

        notify_users(followers - notified, :following, post)
      end
    end

    def author_followers(post)
      User.find(post.user_id).followers.map do |user_id|
        User.find(user_id)
      end
    end
  end

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
