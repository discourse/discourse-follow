# frozen_string_literal: true
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
