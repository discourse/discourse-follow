# frozen_string_literal: true

Follow::Engine.routes.draw do
  put ":username" => "follow#follow",
      :constraints => {
        username: RouteFormat.username,
        format: /(json|html)/,
      },
      :defaults => {
        format: :json,
      }

  delete ":username" => "follow#unfollow",
         :constraints => {
           username: RouteFormat.username,
           format: /(json|html)/,
         },
         :defaults => {
           format: :json,
         }

  get "posts/:username" => "follow#posts",
      :constraints => {
        username: RouteFormat.username,
        format: /(json|html)/,
      },
      :defaults => {
        format: :json,
      }
end

Discourse::Application.routes.draw do
  mount ::Follow::Engine, at: "follow"

  %w[users u].each_with_index do |root_path, index|
    get "#{root_path}/:username/follow" => "follow/follow#index",
        :constraints => {
          username: RouteFormat.username,
        }

    get "#{root_path}/:username/follow/feed" => "follow/follow#index",
        :constraints => {
          username: RouteFormat.username,
        }

    get "#{root_path}/:username/follow/following" => "follow/follow#list_following",
        :constraints => {
          username: RouteFormat.username,
        }

    get "#{root_path}/:username/follow/followers" => "follow/follow#list_followers",
        :constraints => {
          username: RouteFormat.username,
        }
  end
end
