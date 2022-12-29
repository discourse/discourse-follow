# frozen_string_literal: true

class Follow::FollowController < ApplicationController
  FOLLOWING ||= :following
  FOLLOWERS ||= :followers

  def index
  end

  def follow
    raise Discourse::InvalidAccess.new if !current_user

    user = fetch_user
    return if user.blank?

    Follow::Updater.new(current_user, user).watch_follow
    render json: success_json
  end

  def unfollow
    raise Discourse::InvalidAccess.new if !current_user

    user = fetch_user
    return if user.blank?

    Follow::Updater.new(current_user, user).unfollow
    render json: success_json
  end

  def list_following
    list(FOLLOWING)
  end

  def list_followers
    list(FOLLOWERS)
  end

  def posts
    raise Discourse::InvalidAccess.new if !current_user

    user = fetch_user
    return if user.blank?

    ensure_can_see_feed!(user)

    limit = (params[:limit].presence || 20).to_i
    limit = 20 if limit <= 0

    created_before = nil
    if val = params[:created_before].presence
      created_before = validate_date(val)
      if created_before.nil?
        return(
          render json: {
                   errors: [I18n.t("follow.invalid_created_before_date", value: val.inspect)],
                 },
                 status: 400
        )
      end
    end

    posts, has_more = find_posts_feed(user, limit, created_before)
    render_serialized(
      posts,
      FollowPostSerializer,
      root: "posts",
      extras: {
        has_more: has_more,
      },
      rest_serializer: true,
    )
  end

  private

  def list(type)
    user = fetch_user
    return if user.blank?

    if type == FOLLOWERS
      raise Discourse::InvalidAccess.new if !can_see_followers?(user)
      users = user.followers.to_a
    elsif type == FOLLOWING
      raise Discourse::InvalidAccess.new if !can_see_following?(user)
      users = user.following.to_a
    else
      raise Discourse::InvalidParameters.new
    end

    serializer = ActiveModel::ArraySerializer.new(users, each_serializer: BasicUserSerializer)
    render json: MultiJson.dump(serializer)
  end

  def can_see_following?(target_user)
    FollowPagesVisibility.can_see_following_page?(user: current_user, target_user: target_user)
  end

  def can_see_followers?(target_user)
    FollowPagesVisibility.can_see_followers_page?(user: current_user, target_user: target_user)
  end

  def fetch_user
    user = User.find_by_username(params.require(:username))
    if user.blank?
      render json: {
               errors: [I18n.t("follow.user_not_found", username: params[:username].inspect)],
             },
             status: 404
      return nil
    end
    user
  end

  def ensure_can_see_feed!(target_user)
    raise Discourse::InvalidAccess.new if target_user.id != current_user.id && !current_user.staff?
  end

  def validate_date(value)
    value.to_s.to_datetime
  rescue Date::Error
    nil
  end

  def find_posts_feed(target_user, limit, created_before)
    posts =
      UserFollower.posts_for(
        target_user,
        current_user: current_user,
        limit: limit + 1,
        created_before: created_before,
      ).to_a

    has_more = false
    if posts.size == limit + 1
      has_more = true
      posts.pop
    end
    [posts, has_more]
  end
end
