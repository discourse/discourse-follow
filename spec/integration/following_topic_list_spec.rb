# frozen_string_literal: true

require "rails_helper"

describe "/following topic list" do
  fab!(:follower) { Fabricate(:admin) }
  fab!(:followed1) { Fabricate(:admin) }
  fab!(:followed2) { Fabricate(:admin) }

  fab!(:group) { Fabricate(:group) }
  fab!(:secure_category) { Fabricate(:private_category, group: group) }

  before do
    Jobs.run_immediately!
    Follow::Updater.new(follower, followed1).watch_follow
    Follow::Updater.new(follower, followed2).watch_follow
    SiteSetting.enable_whispers = true
    sign_in(follower)
  end

  it "shows topics that followed users have created or participated in" do
    topic1 = create_topic(user: followed1).tap do |t|
      create_post(topic: t, user: followed1) # 1st post
      create_post(topic: t, user: followed2)
    end
    topic2 = create_topic.tap do |t|
      create_post(topic: t)
      create_post(topic: t, user: followed2)
    end
    create_topic.tap do |t|
      create_post(topic: t)
      create_post(topic: t)
    end

    get "/following.json"
    topics = response.parsed_body["topic_list"]["topics"]
    expect(topics.map { |j| j["id"] }).to contain_exactly(topic1.id, topic2.id)
  end

  it "does not show private topics that follower does not have access to" do
    follower.update!(admin: false)
    create_topic(user: Fabricate(:admin), category: secure_category).tap do |t|
      create_post(topic: t, user: t.user) # 1st post
      create_post(topic: t, user: followed1)
    end
    create_topic.tap do |t|
      create_post(topic: t, user: t.user)
      create_post(topic: t, user: followed2, post_type: Post.types[:whisper])
    end
    public_topic = create_topic.tap do |t|
      create_post(topic: t, user: followed2)
    end
    get "/following.json"
    topics = response.parsed_body["topic_list"]["topics"]
    expect(topics.map { |j| j["id"] }).to contain_exactly(public_topic.id)
  end

  it "shows private topics that follower has access to" do
    group.add(follower)
    follower.update!(moderator: true)
    secure_topic = create_topic(user: Fabricate(:admin), category: secure_category).tap do |t|
      create_post(topic: t, user: t.user) # 1st post
      create_post(topic: t, user: followed1)
    end
    whisper_topic = create_topic.tap do |t|
      create_post(topic: t, user: t.user)
      create_post(topic: t, user: followed2, post_type: Post.types[:whisper])
    end
    public_topic = create_topic.tap do |t|
      create_post(topic: t, user: followed2)
    end
    get "/following.json"
    topics = response.parsed_body["topic_list"]["topics"]
    expect(topics.map { |j| j["id"] }).to contain_exactly(
      secure_topic.id,
      whisper_topic.id,
      public_topic.id
    )
  end

  it "does not show topics that contain only moderator posts by a followed user" do
    create_topic.tap do |t|
      create_post(topic: t) # 1st post
      t.update_status("closed", true, followed1)
    end
    normal_topic = create_topic.tap do |t|
      create_post(topic: t, user: followed2)
    end
    get "/following.json"
    topics = response.parsed_body["topic_list"]["topics"]
    expect(topics.map { |j| j["id"] }).to contain_exactly(normal_topic.id)
  end

  it "does not show PMs" do
    create_topic(
      user: followed1,
      archetype: Archetype.private_message,
      target_usernames: follower.username
    ).tap do |t|
      create_post(topic: t, user: followed1) # 1st post
    end
    normal_topic = create_topic.tap do |t|
      create_post(topic: t, user: followed2)
    end
    get "/following.json"
    topics = response.parsed_body["topic_list"]["topics"]
    expect(topics.map { |j| j["id"] }).to contain_exactly(normal_topic.id)
  end

  it "does not show topics that contain only deleted posts by a followed user" do
    create_topic.tap do |t|
      create_post(topic: t, user: t.user) # 1st post
      post = create_post(topic: t, user: followed2)
      PostDestroyer.new(Discourse.system_user, post).destroy
    end
    normal_topic = create_topic.tap do |t|
      create_post(topic: t, user: t.user) # 1st post
      post = create_post(topic: t, user: followed2)
    end
    get "/following.json"
    topics = response.parsed_body["topic_list"]["topics"]
    expect(topics.map { |j| j["id"] }).to contain_exactly(normal_topic.id)
  end
end
