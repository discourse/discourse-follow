# frozen_string_literal: true

require "rails_helper"

describe UserFollower do
  fab!(:admin)
  fab!(:follower) { Fabricate(:user) }
  fab!(:not_followed) { Fabricate(:user) }
  fab!(:followed) { Fabricate(:user) }
  fab!(:followed2) { Fabricate(:user) }

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
      post2 = Fabricate(:post, user: followed, created_at: 1.hours.ago)
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
      followed.user_option.update!(hide_profile_and_presence: true)
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
end
