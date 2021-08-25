require_relative '../plugin_helper'

describe ::Follow::Updater do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }
  fab!(:user4) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }
  fab!(:topic2) { Fabricate(:topic) }

  it "expect users followers to include follower" do
    updater = ::Follow::Updater.new(user1, user2)
    updater.update(true)
    expect(["#{user2.custom_fields['followers']}"]).to eq(["#{user1[:id]}"])
  end

  it "expect users followers to include multiple followers" do
    updater = ::Follow::Updater.new(user1, user2)
    updater.update(true)
    updater = ::Follow::Updater.new(user3, user2)
    updater.update(true)
    expect(["#{user2.custom_fields['followers']}"]).to eq(["#{user1[:id]},#{user3[:id]}"])
  end

  it "sent a notification" do
    updater = ::Follow::Updater.new(user1, user2)
    updater.update(true)
    payload = {
      notification_type: Notification.types[:following],
      data: {
        display_username: user1.username,
        following: true
      }.to_json
    }
    expect(user2.notifications.where(payload).where('created_at >= ?', 1.day.ago).exists?).to eq(true)
  end

  it "sent a notification for original poster and replier" do
    updater = ::Follow::Updater.new(user3, user1)
    updater.update(true)
  
    updater = ::Follow::Updater.new(user3, user2)
    updater.update(true)

    first_post = Fabricate(:post, topic: topic, user: user1)
    second_post = Fabricate(:post, topic: topic, user: user2)
    PostAlerter.post_created(first_post)
    PostAlerter.post_created(second_post)
  
    payload = {
      notification_type: Notification.types[:following_posted],
      data: {
        topic_title: topic.title,
        original_post_id: first_post.id,
        original_post_type: 1,
        original_username: user1.username,
        revision_number: nil,
        display_username: user1.username 
      }.to_json
    }

    expect(user3.notifications.where(payload).where('created_at >= ?', 1.day.ago).exists?).to eq(true)

    payload = {
      notification_type: Notification.types[:following_replied],
      data: {
        topic_title: topic.title,
        original_post_id: second_post.id,
        original_post_type: 1,
        original_username: user2.username,
        revision_number: nil,
        display_username: "2 replies"
      }.to_json
    }

    expect(user3.notifications.where(payload).where('created_at >= ?', 1.day.ago).exists?).to eq(true)
  end
end
