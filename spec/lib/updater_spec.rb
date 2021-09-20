# frozen_string_literal: true

require 'rails_helper'

describe ::Follow::Updater do
  def new_updater(follower, target)
    ::Follow::Updater.new(follower, target)
  end

  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }

  it "does not allow following a bot user" do
    expect do
      new_updater(user1, Discourse.system_user).watch_follow
    end.to raise_error do |error|
      expect(error).to be_a(Discourse::InvalidAccess)
      expect(error.custom_message).to eq("follow.user_cannot_follow_bot")
    end
  end

  it "does not allow following a staged user" do
    user2.update!(staged: true)
    expect do
      new_updater(user1, user2).watch_follow
    end.to raise_error do |error|
      expect(error).to be_a(Discourse::InvalidAccess)
      expect(error.custom_message).to eq("follow.user_cannot_follow_staged")
    end
  end

  it "does not allow following a suspended user" do
    user2.update!(suspended_till: 10.hours.from_now)
    expect do
      new_updater(user1, user2).watch_follow
    end.to raise_error do |error|
      expect(error).to be_a(Discourse::InvalidAccess)
      expect(error.custom_message).to eq("follow.user_cannot_follow_suspended")
    end
  end

  it "does not allow a user to follow themself" do
    expect do
      new_updater(user1, user1).watch_follow
    end.to raise_error do |error|
      expect(error).to be_a(Discourse::InvalidAccess)
      expect(error.custom_message).to eq("follow.user_cannot_follow_themself")
    end
  end

  it "works" do
    new_updater(user1, user2).watch_follow
    expect(user1.following.pluck(:id)).to contain_exactly(user2.id)
    expect(user2.followers.pluck(:id)).to contain_exactly(user1.id)
    relation = user1.following_relations.find_by(user_id: user2.id)
    expect(relation.level).to eq(Follow::Notification.levels[:watching])
  end

  it "sends a notification to the followed user if they opt-in this type " \
  "of notifications and follower allows this notification" do
    user1.custom_fields[:notify_followed_user_when_followed] = true
    user1.save!
    user2.custom_fields[:notify_me_when_followed] = true
    user2.save!
    user2.notifications.destroy_all
    new_updater(user1, user2).watch_follow
    notification = user2.reload.notifications.find_by(
      notification_type: Notification.types[:following]
    )
    expect(notification).to be_present
    data = JSON.parse(notification.data)
    expect(data["display_username"]).to eq(user1.username)
    expect(user1.following.pluck(:id)).to contain_exactly(user2.id)
    expect(user2.followers.pluck(:id)).to contain_exactly(user1.id)
    relation = user1.following_relations.find_by(user_id: user2.id)
    expect(relation.level).to eq(Follow::Notification.levels[:watching])
  end

  it "does not send a notification to the followed user if they opt-out of " \
  "this type of notifications" do
    user1.custom_fields[:notify_followed_user_when_followed] = true
    user1.save!
    user2.custom_fields[:notify_me_when_followed] = false
    user2.save!
    new_updater(user1, user2).watch_follow
    expect(user2.reload.notifications.count).to eq(0)
    expect(user1.following.pluck(:id)).to contain_exactly(user2.id)
    expect(user2.followers.pluck(:id)).to contain_exactly(user1.id)
    relation = user1.following_relations.find_by(user_id: user2.id)
    expect(relation.level).to eq(Follow::Notification.levels[:watching])
  end

  it "does not send a notification to the followed user if the follower " \
  "does not allow this notification to be sent out" do
    user1.custom_fields[:notify_followed_user_when_followed] = false
    user1.save!
    user2.custom_fields[:notify_me_when_followed] = true
    user2.save!
    new_updater(user1, user2).watch_follow
    expect(user2.reload.notifications.count).to eq(0)
    expect(user1.following.pluck(:id)).to contain_exactly(user2.id)
    expect(user2.followers.pluck(:id)).to contain_exactly(user1.id)
    relation = user1.following_relations.find_by(user_id: user2.id)
    expect(relation.level).to eq(Follow::Notification.levels[:watching])
  end

  it "does not send a notification to the followed user if the " \
  "follow_notifications_enabled site setting is off" do
    SiteSetting.follow_notifications_enabled = false
    user1.custom_fields[:notify_followed_user_when_followed] = true
    user1.save!
    user2.custom_fields[:notify_me_when_followed] = true
    user2.save!
    new_updater(user1, user2).watch_follow
    expect(user2.reload.notifications.count).to eq(0)
    expect(user1.following.pluck(:id)).to contain_exactly(user2.id)
    expect(user2.followers.pluck(:id)).to contain_exactly(user1.id)
    relation = user1.following_relations.find_by(user_id: user2.id)
    expect(relation.level).to eq(Follow::Notification.levels[:watching])
  end

  it "does not send a notification to the followed user if there is " \
  "a follow notification from the same follower within the last 24 hours" do
    user1.custom_fields[:notify_followed_user_when_followed] = true
    user1.save!
    user2.custom_fields[:notify_me_when_followed] = true
    user2.save!

    expect do
      new_updater(user1, user2).watch_follow
    end.to change {
      user2.reload.notifications.where(notification_type: Notification.types[:following]).count
    }.by(1)
    expect(user1.following.pluck(:id)).to contain_exactly(user2.id)
    expect(user2.followers.pluck(:id)).to contain_exactly(user1.id)
    relation = user1.following_relations.find_by(user_id: user2.id)
    expect(relation.level).to eq(Follow::Notification.levels[:watching])

    freeze_time 6.hours.from_now

    new_updater(user1, user2).unfollow
    expect(user1.reload.following.pluck(:id)).to eq([])
    expect(user2.reload.followers.pluck(:id)).to eq([])
    expect(
      user2
        .notifications
        .where(notification_type: Notification.types[:following])
        .count
    ).to eq(1) # unchanged

    # follow again
    expect do
      new_updater(user1, user2).watch_follow
    end.to change {
      user2.reload.notifications.where(notification_type: Notification.types[:following]).count
    }.by(0)
    expect(user1.following.pluck(:id)).to contain_exactly(user2.id)
    expect(user2.followers.pluck(:id)).to contain_exactly(user1.id)
    relation = user1.following_relations.find_by(user_id: user2.id)
    expect(relation.level).to eq(Follow::Notification.levels[:watching])

    # following another user will result in a notification
    user3.custom_fields[:notify_me_when_followed] = true
    user3.save!
    expect do
      new_updater(user1, user3).watch_follow
    end.to change {
      user3.reload.notifications.where(notification_type: Notification.types[:following]).count
    }.by(1)
    expect(user1.following.pluck(:id)).to contain_exactly(user2.id, user3.id)
    expect(user3.followers.pluck(:id)).to contain_exactly(user1.id)
    relation = user1.following_relations.find_by(user_id: user3.id)
    expect(relation.level).to eq(Follow::Notification.levels[:watching])
  end
end
