# frozen_string_literal: true

require "rails_helper"

describe UserFollower do
  fab!(:admin)
  fab!(:follower, :user)
  fab!(:not_followed, :user)
  fab!(:followed, :user)
  fab!(:followed2, :user)

  fab!(:group)
  fab!(:secure_category) { Fabricate(:private_category, group: group) }

  before do
    SiteSetting.discourse_follow_enabled = true
    Follow::Updater.new(follower, followed).watch_follow
    Follow::Updater.new(follower, followed2).watch_follow
  end

  describe ".posts_for" do
    it "does not show posts in PMs" do
      Fabricate(:private_message_post, user: followed)
      posts = UserFollower.posts_for(follower, current_user: admin)
      expect(posts.pluck(:id)).to be_blank
    end

    it "filters with created_before" do
      Fabricate(:post, user: followed, topic: Fabricate(:topic), created_at: 1.day.ago)
      post_2 = Fabricate(:post, user: followed, topic: Fabricate(:topic), created_at: 2.days.ago)

      posts = UserFollower.posts_for(follower, current_user: admin, created_before: 25.hours.ago)
      expect(posts).to contain_exactly(post_2)
    end

    it "filters with created_after" do
      Fabricate(:post, user: followed, topic: Fabricate(:topic), created_at: 2.days.ago)
      post_2 = Fabricate(:post, user: followed, topic: Fabricate(:topic), created_at: 1.day.ago)

      posts = UserFollower.posts_for(follower, current_user: admin, created_after: 25.hours.ago)
      expect(posts).to contain_exactly(post_2)
    end

    it "does not show posts in unlisted topics" do
      post = Fabricate(:post, user: followed)
      post.topic.update_status("visible", false, Discourse.system_user)
      posts = UserFollower.posts_for(follower, current_user: admin)
      expect(posts.pluck(:id)).to be_blank
    end

    it "does not show posts in secured categories that current user does " \
         "not have access to" do
      post = Fabricate(:post, user: followed, topic: Fabricate(:topic, category: secure_category))
      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to be_blank
    end

    it "does not show deleted posts" do
      post = Fabricate(:post, user: followed)
      post.update!(deleted_at: 1.minute.ago)
      posts = UserFollower.posts_for(follower, current_user: admin)
      expect(posts.pluck(:id)).to be_blank
    end

    it "does not show posts in deleted topics" do
      post = Fabricate(:post, user: followed)
      post.topic.update!(deleted_at: 1.minute.ago)
      posts = UserFollower.posts_for(follower, current_user: admin)
      expect(posts.pluck(:id)).to be_blank
    end

    it "does not show whispers if current user cannot see them" do
      Fabricate(:whisper, user: followed)
      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to be_blank
    end

    it "shows whispers if current user can see them" do
      post = Fabricate(:whisper, user: followed)
      posts = UserFollower.posts_for(follower, current_user: admin)
      expect(posts.pluck(:id)).to contain_exactly(post.id)
    end

    it "shows posts in uncategorized topics" do
      post =
        Fabricate(
          :post,
          user: followed,
          topic: Fabricate(:topic, category_id: SiteSetting.uncategorized_category_id),
        )
      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to contain_exactly(post.id)
    end

    it "does not show small action posts" do
      Fabricate(:small_action, user: followed)
      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to be_blank
    end

    it "shows posts made by followed users only" do
      expected = []
      post = Fabricate(:post, user: followed)
      expected << post
      expected << Fabricate(:post, user: followed, topic: post.topic)
      expected << Fabricate(:post, user: followed2, topic: post.topic)
      expected << Fabricate(:post, user: followed2)
      Fabricate(:post, user: not_followed)
      Fabricate(:post, user: not_followed, topic: post.topic)
      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to contain_exactly(*expected.pluck(:id))
    end

    it "can limit the number of returned posts" do
      5.times { |n| Fabricate(:post, user: [followed, followed2].sample, created_at: n.hours.ago) }
      posts = UserFollower.posts_for(follower, current_user: follower, limit: 3)
      expect(posts.size).to eq(3)
      posts = UserFollower.posts_for(follower, current_user: follower, limit: 6)
      expect(posts.size).to eq(5)
    end

    it "orders returned posts in reversed chronological order" do
      post1 = Fabricate(:post, user: followed, created_at: 3.hours.ago)
      post2 = Fabricate(:post, user: followed, created_at: 1.hour.ago)
      post3 = Fabricate(:post, user: followed, created_at: 9.hours.ago)
      posts = UserFollower.posts_for(follower, current_user: follower, limit: 3)
      expect(posts.pluck(:id)).to eq([post2.id, post1.id, post3.id])
    end

    it "does not include posts from followed users who have disabled follows" do
      post1 = Fabricate(:post, user: followed)
      post2 = Fabricate(:post, user: followed2)
      followed.custom_fields["allow_people_to_follow_me"] = false
      followed.save!
      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to contain_exactly(post2.id)
    end

    it "does not include posts from followed users who have hidden their profile" do
      post1 = Fabricate(:post, user: followed)
      post2 = Fabricate(:post, user: followed2)
      followed.user_option.update!(hide_profile: true)
      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to contain_exactly(post2.id)
    end

    it "does not include small action posts" do
      post1 = Fabricate(:post, user: followed, post_type: Post.types[:small_action])
      post2 =
        Fabricate(
          :post,
          user: followed,
          post_type: Post.types[:small_action],
          action_code: "closed.enabled",
        )
      post3 =
        Fabricate(:post, user: followed, post_type: Post.types[:whisper], action_code: "assigned")

      follower.update!(admin: true)
      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to be_blank
    end

    it "includes moderator posts" do
      post1 = Fabricate(:post, user: followed, post_type: Post.types[:moderator_action])

      posts = UserFollower.posts_for(follower, current_user: follower)
      expect(posts.pluck(:id)).to contain_exactly(post1.id)
    end

    context "when default_allow_people_to_follow_me setting is false" do
      before { SiteSetting.default_allow_people_to_follow_me = false }

      it "only include posts if followed user has explicitly allowed people to follow them" do
        post1 = Fabricate(:post, user: followed)
        post2 = Fabricate(:post, user: followed2)
        followed.custom_fields["allow_people_to_follow_me"] = true
        followed.save!
        posts = UserFollower.posts_for(follower, current_user: follower)
        expect(posts.pluck(:id)).to contain_exactly(post1.id)

        followed.custom_fields["allow_people_to_follow_me"] = false
        followed.save!
        followed2.custom_fields["allow_people_to_follow_me"] = true
        followed2.save!
        posts = UserFollower.posts_for(follower, current_user: follower)
        expect(posts.pluck(:id)).to contain_exactly(post2.id)
      end
    end
  end

  describe ".topics_for" do
    it "does not show topics in PMs" do
      Fabricate(:private_message_topic, user: followed)
      topics = UserFollower.topics_for(follower, current_user: admin)
      expect(topics.pluck(:id)).to be_blank
    end

    it "filters with created_before" do
      topic_1 = Fabricate(:topic, user: followed, created_at: 1.day.ago)
      topic_2 = Fabricate(:topic, user: followed, created_at: 2.days.ago)

      topics = UserFollower.topics_for(follower, current_user: admin, created_before: 25.hours.ago)
      expect(topics).to contain_exactly(topic_2)
    end

    it "filters with created_after" do
      Fabricate(:topic, user: followed, created_at: 2.days.ago)
      topic_2 = Fabricate(:topic, user: followed, created_at: 1.day.ago)

      topics = UserFollower.topics_for(follower, current_user: admin, created_after: 25.hours.ago)
      expect(topics).to contain_exactly(topic_2)
    end

    it "does not show unlisted topics" do
      topic = Fabricate(:topic, user: followed)
      topic.update_status("visible", false, Discourse.system_user)
      topics = UserFollower.topics_for(follower, current_user: admin)
      expect(topics.pluck(:id)).to be_blank
    end

    it "does not show topics in secured categories that current user does " \
         "not have access to" do
      Fabricate(:topic, user: followed, category: secure_category)
      topics = UserFollower.topics_for(follower, current_user: follower)
      expect(topics.pluck(:id)).to be_blank
    end

    it "does not show deleted topics" do
      topic = Fabricate(:topic, user: followed)
      topic.update!(deleted_at: 1.minute.ago)
      topics = UserFollower.topics_for(follower, current_user: admin)
      expect(topics.pluck(:id)).to be_blank
    end

    describe "it behaves like posts_for" do
      it "brings topics the same way as posts_for" do
        Fabricate(:post, user: followed)
        topics = UserFollower.topics_for(follower, current_user: admin)
        topic_ids_from_posts_for =
          UserFollower.posts_for(follower, current_user: admin).map(&:topic_id)

        expect(topics.pluck(:id)).to contain_exactly(*topic_ids_from_posts_for)
      end

      it "does not show repeated topics" do
        topic = Fabricate(:topic, user: followed)
        Fabricate.times(3, :post, user: followed, topic: topic)

        topics = UserFollower.topics_for(follower, current_user: admin)
        expect(topics.size).to eq(1)

        posts = UserFollower.posts_for(follower, current_user: admin)
        expect(posts.size).to eq(3)
      end
    end
  end
end
