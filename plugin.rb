# name: discourse-follow
# about: Discourse Follow
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-follow

register_asset 'stylesheets/common/follow.scss'

if respond_to?(:register_svg_icon)
  register_svg_icon "user-minus"
end

after_initialize do
  module ::Follow
    class Engine < ::Rails::Engine
      engine_name "follow"
      isolate_namespace Follow
    end
  end

  class ::User
    def following
      if custom_fields['following']
        custom_fields['following'].split(',')
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
        followers = user.followers
        following = current_user.following

        if ActiveModel::Type::Boolean.new.cast(params[:follow])
          followers.push(current_user.id) if followers.exclude?(current_user.id.to_s)
          following.push(user.id) if following.exclude?(user.id.to_s)
        else
          followers.delete(current_user.id.to_s)
          following.delete(user.id.to_s)
        end

        user.custom_fields['followers'] = followers.join(',')
        current_user.custom_fields['following'] = following.join(',')

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

      user = User.find_by(username: params[:username])

      users = user.send(params[:type]).map do |user_id|
        User.find(user_id)
      end

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

  add_to_serializer(:user, :following) { object.followers.include?(scope.current_user.id.to_s) }
  add_to_serializer(:user, :include_following?) { scope.current_user }
  add_to_serializer(:user, :total_followers) { object.followers.length }
  add_to_serializer(:user, :include_total_followers?) { SiteSetting.follow_show_statistics_on_profile }
  add_to_serializer(:user, :total_following) { object.following.length }
  add_to_serializer(:user, :include_total_following?) { SiteSetting.follow_show_statistics_on_profile }
end
