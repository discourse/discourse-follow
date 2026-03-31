# frozen_string_literal: true

class Follow::Updater
  def initialize(follower, target)
    @follower = follower
    @target = target
  end

  def watch_follow
    follow(Follow::Notification.levels[:watching])
  end

  def unfollow
    UserFollower.where(follower_id: @follower.id, user_id: @target.id).destroy_all
  end

  private

  def follow(notification_level)
    ensure_can_follow!

    if !Follow::Notification.levels.invert.key?(notification_level)
      raise Discourse::InvalidParameters.new(
              I18n.t("follow.invalid_notification_level", level: notification_level.inspect),
            )
    end

    relation = UserFollower.find_or_initialize_by(user_id: @target.id, follower_id: @follower.id)
    relation.level = notification_level
    relation.save!

    payload = {
      notification_type: Notification.types[:following],
      data: { display_username: @follower.username }.to_json,
    }
    send_notification(payload) if should_notify?(payload)

    relation
  end

  def ensure_can_follow!
    guardian = Guardian.new(@follower)
    return if guardian.can_follow?(@target)

    raise_invalid_access("follow.user_cannot_follow_themself") if @target.id == @follower.id

    %i[bot staged suspended].each do |status|
      if @target.public_send(:"#{status}?")
        raise_invalid_access("follow.user_cannot_follow_#{status}")
      end
    end

    raise_invalid_access("follow.user_does_not_allow_follow", username: @target.username)
  end

  def raise_invalid_access(custom_message, **params)
    raise Discourse::InvalidAccess.new(
            nil,
            nil,
            custom_message:,
            custom_message_params: params.presence,
          )
  end

  def should_notify?(payload)
    SiteSetting.follow_notifications_enabled && @follower.notify_followed_user_when_followed &&
      @target.notify_me_when_followed && !notification_sent_recently(payload)
  end

  def send_notification(payload)
    @target.notifications.create!(payload)
  end

  def notification_sent_recently(payload)
    @target.notifications.where(payload).where("created_at >= ?", 1.day.ago).exists?
  end
end
