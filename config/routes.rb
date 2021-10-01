# frozen_string_literal: true

Follow::Engine.routes.draw do
  put ":username" => "follow#follow", constraints: { username: RouteFormat.username, format: /(json|html)/ }, defaults: { format: :json }
  delete ":username" => "follow#unfollow", constraints: { username: RouteFormat.username, format: /(json|html)/ }, defaults: { format: :json }
  get "posts/:username" => "follow#posts", constraints: { username: RouteFormat.username, format: /(json|html)/ }, defaults: { format: :json }
end
