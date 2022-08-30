# frozen_string_literal: true

require 'rails_helper'

describe "Follow plugin notifications" do
  def follow_notification_assertions(notification, followed, post, topic)
    expect(notification).to be_present
    expect(notification.post_number).to eq(post.post_number)

    data = JSON.parse(notification.data)
    expect(data["display_username"]).to eq(followed.username)
    expect(data["topic_title"]).to eq(topic.title)
    expect(data["original_post_id"]).to eq(post.id)
    expect(data["original_post_type"]).to eq(post.post_type)
  end

  fab!(:follower) { Fabricate(:user) }
  fab!(:followed) { Fabricate(:admin) }
  fab!(:followed2) { Fabricate(:user) }
  fab!(:followed3) { Fabricate(:user) }
  fab!(:normal_user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }

  let(:topic) do
    create_topic(category: category).tap do |t|
      create_post(topic: t) # make sure there is a first post
    end
  end

  before do
    SiteSetting.discourse_follow_enabled = true
    Jobs.run_immediately!
    Follow::Updater.new(follower, followed).watch_follow
    Notification.destroy_all
    follower.custom_fields[:notify_me_when_followed_replies] = true
    follower.custom_fields[:notify_me_when_followed_creates_topic] = true
    follower.save!
  end

  context "when followed user posts in a category that a follower cannot see" do
    let(:group) { Fabricate(:group) }
    let(:secure_category) { Fabricate(:private_category, group: group) }
    let(:secure_topic) do
      create_topic(category: secure_category, user: followed).tap do |t|
        create_post(topic: t, user: followed)
      end
    end

    before do
      create_post(topic: secure_topic, user: followed)
    end

    it "follower does not receive any notifications" do
      expect(follower.notifications.count).to eq(0)
    end
  end

  context "when followed user posts in a PM" do
    let(:pm) do
      create_topic(
        user: followed,
        archetype: Archetype.private_message,
        target_usernames: follower.username
      )
    end

    before do
      create_post(user: followed, topic: pm)
    end

    it "follower receives no notifications from the plugin" do
      expect(follower.notifications.where.not(
        notification_type: Notification.types[:private_message]
      ).count).to eq(0)
    end
  end

  context "when topic notification level is watching" do
    before do
      TopicUser.create!(
        user: follower,
        topic: topic,
        last_read_post_number: 1,
        notification_level: TopicUser.notification_levels[:watching]
      )
      @notification_post = create_post(topic: topic, user: followed)
    end

    it "follower receives a notification that a followed user has posted" do
      notification = follower.notifications.find_by(
        topic_id: topic.id,
        notification_type: Notification.types[:following_replied]
      )
      follow_notification_assertions(notification, followed, @notification_post, topic)
    end

    it "follower receives only 1 notification for the post" do
      expect(follower.notifications.count).to eq(1)
    end
  end

  context "when topic notification level is muted" do
    before do
      TopicUser.create!(
        user: follower,
        topic: topic,
        notification_level: TopicUser.notification_levels[:muted]
      )
      create_post(topic: topic, user: followed)
    end

    it "follower receives no notifications" do
      expect(follower.notifications.count).to eq(0)
    end
  end

  context "when topic notification level is normal" do
    before do
      @notification_post = create_post(topic: topic, user: followed)
    end

    it "follower receives a notification that a followed user has posted" do
      notification = follower.notifications.find_by(
        topic_id: topic.id,
        notification_type: Notification.types[:following_replied]
      )
      follow_notification_assertions(notification, followed, @notification_post, topic)
    end

    it "follower receives only 1 notification" do
      expect(follower.notifications.count).to eq(1)
    end
  end

  context "when category notification level is watching" do
    before do
      # this will create the topic by a non-followed user and then
      # creates a post by a followed user
      @notification_post = create_post(topic: topic, user: followed)

      CategoryUser.set_notification_level_for_category(
        follower,
        CategoryUser.notification_levels[:watching],
        category.id
      )
    end

    it "follower receives only a notification" do
      expect(follower.notifications.count).to eq(1)
    end

    it "follower receives a notification for the post made by the followed user" do
      notification = follower.notifications.find_by(
        topic_id: topic.id,
        notification_type: Notification.types[:following_replied]
      )
      follow_notification_assertions(notification, followed, @notification_post, topic)
    end
  end

  context "when followed user mentions a follower watching the category" do
    before do
      CategoryUser.set_notification_level_for_category(
        follower,
        CategoryUser.notification_levels[:watching],
        category.id
      )
      @notification_post = create_post(
        topic: topic,
        user: followed,
        raw: "hello @#{follower.username}"
      )
    end

    it "follower receives 2 notifications" do
      expect(follower.notifications.size).to eq(2)
    end

    it "follower receives mention notification" do
      notification = follower.notifications.find_by(
        topic_id: topic.id,
        notification_type: Notification.types[:mentioned]
      )
      expect(notification).to be_present
      expect(notification.post_number).to eq(@notification_post.post_number)
    end

    it "follower receives a notification for the 1st post in the topic because " \
    "they watch the category" do
      notification = follower.notifications.find_by(
        topic_id: topic.id,
        notification_type: Notification.types[:posted]
      )
      expect(notification).to be_present
      expect(notification.post_number).to eq(1)
    end
  end

  context "when followed user replies directory to a follower watching the category" do
    before do
      CategoryUser.set_notification_level_for_category(
        follower,
        CategoryUser.notification_levels[:watching],
        category.id
      )
      follower_post = create_post(topic: topic, user: follower)
      @notification_post = create_post(
        topic: topic,
        user: followed,
        reply_to_post_number: follower_post.post_number
      )
    end

    it "follower receives a notification about the reply" do
      notification = follower.notifications.find_by(
        topic: topic,
        notification_type: Notification.types[:replied]
      )
      expect(notification).to be_present
      expect(notification.post_number).to eq(@notification_post.post_number)
      data = JSON.parse(notification.data)
      expect(data["display_username"]).to eq(followed.username)
    end

    it "follower receives only 1 notification" do
      expect(follower.notifications.count).to eq(1)
    end
  end

  context "when multiple followed users and non-followed users post in a topic" do
    before do
      Follow::Updater.new(follower, followed2).watch_follow
      Follow::Updater.new(follower, followed3).watch_follow
      Notification.destroy_all

      @collapsed_first_post = create_post(user: followed2, topic: topic)
      create_post(user: normal_user, topic: topic)
      create_post(user: followed3, topic: topic)
      create_post(user: followed, topic: topic)
      @collapsed_last_post = create_post(user: followed3, topic: topic)
      create_post(user: normal_user, topic: topic)
    end

    it "notification for followed users' replies are collapsed" do
      expect(follower.notifications.count).to eq(1)
      notification = follower.notifications.find_by(
        topic: topic,
        notification_type: Notification.types[:following_replied]
      )
      expect(notification).to be_present
      expect(notification.post_number).to eq(@collapsed_first_post.post_number)
      data = JSON.parse(notification.data)
      expect(data["original_post_id"]).to eq(@collapsed_last_post.id)
      expect(data["display_username"]).to eq(I18n.t("embed.replies", count: 4))
    end
  end

  context "when multiple followed and non-followed users post and reply to a follower" do
    before do
      Follow::Updater.new(follower, followed2).watch_follow
      Follow::Updater.new(follower, followed3).watch_follow
      Notification.destroy_all

      follower_post = create_post(user: follower, topic: topic)
      @collapsed_follow_notification_first_post = create_post(user: followed2, topic: topic)
      @collapsed_reply_notification_first_post = create_post(
        user: normal_user,
        topic: topic,
        reply_to_post_number: follower_post.post_number
      )
      create_post(user: followed3, topic: topic)
      @collapsed_reply_notification_last_post = create_post(
        user: followed,
        topic: topic,
        reply_to_post_number: follower_post.post_number
      )
      @collapsed_follow_notification_last_post = create_post(user: followed3, topic: topic)
      create_post(user: normal_user, topic: topic)
    end

    it "follower receives 2 notifications" do
      expect(follower.notifications.count).to eq(2)
    end

    it "follower receives a notification about the posts made by the followed users" do
      notification = follower.notifications.find_by(
        topic: topic,
        notification_type: Notification.types[:following_replied]
      )
      expect(notification).to be_present
      expect(notification.post_number).to eq(@collapsed_follow_notification_first_post.post_number)
      data = JSON.parse(notification.data)
      expect(data["original_post_id"]).to eq(@collapsed_follow_notification_last_post.id)
      expect(data["display_username"]).to eq(I18n.t("embed.replies", count: 4))
    end

    it "follower receives a notification about the replies to their post" do
      notification = follower.notifications.find_by(
        topic: topic,
        notification_type: Notification.types[:replied]
      )
      expect(notification).to be_present
      expect(notification.post_number).to eq(@collapsed_reply_notification_first_post.post_number)
      data = JSON.parse(notification.data)
      expect(data["original_post_id"]).to eq(@collapsed_reply_notification_last_post.id)
      expect(data["display_username"]).to eq(I18n.t("embed.replies", count: 2))
    end
  end

  context "when a followed user closes a topic" do
    before do
      topic.update_status("closed", true, followed)
    end

    it "follower does not receive a notification for the small post" do
      expect(follower.notifications.count).to eq(0)
    end
  end

  context "when a followed user posts a whisper" do
    before do
      SiteSetting.enable_whispers = true
    end

    it "follower does not receive a notification for the whisper if they can not see it" do
      create_post(topic: topic, user: followed, post_type: Post.types[:whisper])
      expect(follower.notifications.count).to eq(0)
    end

    it "follower receives a notification for the whisper if they can see it" do
      follower.update!(moderator: true)
      whisper_post = create_post(topic: topic, user: followed, post_type: Post.types[:whisper])
      expect(follower.notifications.count).to eq(1)
      notification = follower.notifications.find_by(
        topic: topic,
        notification_type: Notification.types[:following_replied]
      )
      follow_notification_assertions(notification, followed, whisper_post, topic)
    end
  end

  context "when follower opts out of notifications completely" do
    before do
      follower.custom_fields[:notify_me_when_followed_replies] = false
      follower.custom_fields[:notify_me_when_followed_creates_topic] = false
      follower.save!
    end

    it "they receive no notifications when a followed user replies" do
      create_post(topic: topic, user: followed)
      expect(follower.notifications.count).to eq(0)
    end

    it "they receive no notifications when a followed user creates a topic" do
      t = create_topic(user: followed)
      create_post(user: followed, topic: t) # creates 1st post
      expect(follower.notifications.count).to eq(0)
    end
  end

  context "when follower opts out of replies notifications" do
    before do
      follower.custom_fields[:notify_me_when_followed_replies] = false
      follower.custom_fields[:notify_me_when_followed_creates_topic] = true
      follower.save!
    end

    it "they receive no notifications when a followed user replies" do
      create_post(topic: topic, user: followed)
      expect(follower.notifications.count).to eq(0)
    end

    it "they receive a notification when a followed user creates a topic" do
      t = create_topic(user: followed)
      post = create_post(user: followed, topic: t) # creates 1st post
      expect(follower.notifications.count).to eq(1)
      notification = follower.notifications.find_by(
        topic_id: t.id,
        notification_type: Notification.types[:following_created_topic]
      )
      follow_notification_assertions(notification, followed, post, t)
    end
  end

  context "when follow_notifications_enabled site setting is off" do
    before do
      SiteSetting.follow_notifications_enabled = false
    end

    it "follower does not receive any notifications when followed user replies" do
      create_post(topic: topic, user: followed)
      expect(follower.notifications.count).to eq(0)
    end

    it "follower does not receive any notifications when followed user creates a topic" do
      t = create_topic(user: followed)
      post = create_post(user: followed, topic: t) # creates 1st post
      expect(follower.notifications.count).to eq(0)
    end
  end

  context "when the followed user has disabled follows but has existing followers" do
    it "the followers no longer receive notification for posts made by the followed user" do
      expect(followed.followers.count).to be > 0
      followed.custom_fields["allow_people_to_follow_me"] = false
      followed.save!
      create_topic(user: followed).tap do |t|
        create_post(topic: t, user: followed)
      end
      followed.followers.each do |follower|
        expect(follower.notifications.count).to eq(0)
      end
    end
  end

  context "when the followed user has hidden profile but has existing followers" do
    it "the followers no longer receive notification for posts made by the followed user" do
      expect(followed.followers.count).to be > 0
      followed.user_option.update!(hide_profile_and_presence: true)
      create_topic(user: followed).tap do |t|
        create_post(topic: t, user: followed)
      end
      followed.followers.each do |follower|
        expect(follower.notifications.count).to eq(0)
      end
    end
  end
end
