# frozen_string_literal: true
class Follow::FollowController < ApplicationController
  def index
  end

  def update
    params.require(:username)
    params.require(:follow)

    raise Discourse::InvalidAccess.new unless current_user
    raise Discourse::InvalidParameters.new if current_user.username == params[:username]

    if user = User.find_by(username: params[:username])
      updater = Follow::Updater.new(current_user, user)
      updater.update(params[:follow])

      following = user.followers.include?(current_user.id.to_s)

      render json: success_json.merge(following: following)
    else
      render json: failed_json
    end
  end

  def list
    params.require(:type)
    params.require(:username)

    user = User.where('lower(username) = ?', params[:username].downcase).first
    raise Discourse::InvalidParameters.new unless user.present?

    type = params[:type]
    allowed = SiteSetting.try("follow_#{type}_visible") || nil

    if allowed == 'all' || (allowed == 'self' && (user.id == current_user.id))
      method = type == 'following' ? 'following_ids' : 'followers'
      users = user.send(method).map { |user_id| User.find(user_id) }

      serializer = ActiveModel::ArraySerializer.new(users, each_serializer: BasicUserSerializer)
      render json: MultiJson.dump(serializer)
    else
      render json: []
    end
  end
end
