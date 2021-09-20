# frozen_string_literal: true

class Follow::FollowController < ApplicationController
  FOLLOWING ||= :following
  FOLLOWERS ||= :followers

  def follow
    raise Discourse::InvalidAccess.new if !current_user

    user = User.find_by_username(params.require(:username))
    if user.blank?
      return render json: {
        errors: [I18n.t("follow.user_not_found", username: params[:username].inspect)]
      }, status: 404
    end

    Follow::Updater.new(current_user, user).watch_follow
    render json: success_json
  end

  def unfollow
    raise Discourse::InvalidAccess.new if !current_user

    user = User.find_by_username(params.require(:username))
    if user.blank?
      return render json: {
        errors: [I18n.t("follow.user_not_found", username: params[:username].inspect)]
      }, status: 404
    end

    Follow::Updater.new(current_user, user).unfollow
    render json: success_json
  end

  def list_following
    list(FOLLOWING)
  end

  def list_followers
    list(FOLLOWERS)
  end

  private

  def list(type)
    user = User.find_by_username(params.require(:username))
    raise Discourse::NotFound.new if user.blank?

    if type == FOLLOWERS
      if !FollowPagesVisibility.can_see_followers_page?(user: current_user, target_user: user)
        raise Discourse::InvalidAccess.new
      end
      users = user.followers.to_a
    elsif type == FOLLOWING
      if !FollowPagesVisibility.can_see_following_page?(user: current_user, target_user: user)
        raise Discourse::InvalidAccess.new
      end
      users = user.following.to_a
    else
      raise Discourse::InvalidParameters.new
    end

    serializer = ActiveModel::ArraySerializer.new(users, each_serializer: BasicUserSerializer)
    render json: MultiJson.dump(serializer)
  end
end
