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
    if @target.id == @follower.id
      raise Discourse::InvalidAccess.new(
              nil,
              nil,
              custom_message: "follow.user_cannot_follow_themself",
            )
    end

    %i[bot staged suspended].each do |status|
      if @target.public_send(:"#{status}?")
        raise Discourse::InvalidAccess.new(
                nil,
                nil,
                custom_message: "follow.user_cannot_follow_#{status}",
              )
      end
    end

    if !Follow::Notification.levels.invert.key?(notification_level)
      raise Discourse::InvalidParameters.new(
              I18n.t("follow.invalid_notification_level", level: notification_level.inspect),
            )
    end

    if !@target.allow_people_to_follow_me
      raise Discourse::InvalidAccess.new(
              nil,
              nil,
              custom_message: "follow.user_does_not_allow_follow",
              custom_message_params: {
                username: @target.username,
              },
            )
    end

    if @target.user_option&.hide_profile_and_presence
      raise Discourse::InvalidAccess.new(
              nil,
              nil,
              custom_message: "follow.user_does_not_allow_follow",
              custom_message_params: {
                username: @target.username,
              },
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
