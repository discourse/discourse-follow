# frozen_string_literal: true

require "rails_helper"

describe Follow::FollowController do
  fab!(:user1, :user)
  fab!(:user2, :user)
  fab!(:tl4) { Fabricate(:user, trust_level: TrustLevel[4]) }
  fab!(:tl3) { Fabricate(:user, trust_level: TrustLevel[3]) }
  fab!(:tl2) { Fabricate(:user, trust_level: TrustLevel[2]) }

  before { SiteSetting.discourse_follow_enabled = true }

  def expect_not_allowed(user, type)
    get "/u/#{user.username}/follow/#{type}.json"
    expect(response.status).to eq(403)
  end

  def expect_allowed(user, type)
    if type == "followers"
      expected_ids = user.followers.pluck(:id)
    elsif type == "following"
      expected_ids = user.following.pluck(:id)
    else
      raise "unknown type #{type.inspect}"
    end

    get "/u/#{user.username}/follow/#{type}.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body.map { |j| j["id"] }).to contain_exactly(*expected_ids)
  end

  def response_topic_ids(response)
    response.parsed_body["posts"].map { |t| t["id"] }
  end

  %w[followers following].each do |type|
    describe "#list_#{type}" do
      before do
        ::Follow::Updater.new(user1, user2).watch_follow
        ::Follow::Updater.new(user2, user1).watch_follow
      end

      context "when follow_#{type}_visible setting is set to no-one" do
        before { SiteSetting.public_send("follow_#{type}_visible=", FollowPagesVisibility::NO_ONE) }

        it "tl4 users cannot see other users pages" do
          sign_in(tl4)
          expect_not_allowed(user1, type)
        end

        it "tl4 users cannot see their pages" do
          sign_in(tl4)
          expect_not_allowed(tl4, type)
        end
      end

      context "when follow_#{type}_visible setting is set to everyone" do
        before do
          SiteSetting.public_send("follow_#{type}_visible=", FollowPagesVisibility::EVERYONE)
        end

        it "anon users can see pages of normal users" do
          expect_allowed(user1, type)
        end
      end

      context "when follow_#{type}_visible setting is set to a specific trust level group" do
        before do
          SiteSetting.public_send("follow_#{type}_visible=", "trust_level_3")
          Group.refresh_automatic_groups!
        end

        it "anon users cannot see pages of normal users" do
          expect_not_allowed(user1, type)
        end

        it "users with enough trust level can see pages of other users" do
          sign_in(tl4)
          expect_allowed(user1, type)
          sign_in(tl3)
          expect_allowed(user1, type)
        end

        it "users without enough trust level cannot see pages of other users" do
          sign_in(tl2)
          expect_not_allowed(user1, type)
        end

        it "users can still see their own pages" do
          sign_in(user1)
          expect_allowed(user1, type)
          sign_in(user2)
          expect_allowed(user2, type)
        end
      end
    end
  end

  describe "#follow" do
    it "updates followers" do
      sign_in(user1)

      put "/follow/#{user2.username}.json"

      expect(response.status).to eq(200)
      expect(user1.reload.following.pluck(:id)).to contain_exactly(user2.id)
      expect(user2.reload.followers.pluck(:id)).to contain_exactly(user1.id)
    end

    it "responds with 404 if user does not exist" do
      sign_in(user1)

      put "/follow/doesnotexist.json"
      expect(response.status).to eq(404)
      expect(response.parsed_body["errors"]).to include(
        I18n.t("follow.user_not_found", username: "doesnotexist".inspect),
      )
    end

    it "responds with 403 if the followed user has disabled follows" do
      user2.custom_fields["allow_people_to_follow_me"] = false
      user2.save!
      sign_in(user1)

      put "/follow/#{user2.username}.json"

      expect(response.status).to eq(403)
      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("follow.user_does_not_allow_follow", username: user2.username),
      )
      expect(user2.reload.followers.count).to eq(0)
    end
  end

  describe "#unfollow" do
    before do
      ::Follow::Updater.new(user1, user2).watch_follow
      ::Follow::Updater.new(user2, user1).watch_follow
    end

    it "removes follower" do
      sign_in(user1)
      delete "/follow/#{user2.username}.json"
      expect(user1.reload.following.count).to eq(0)
      expect(user2.reload.following.count).to eq(1)
    end

    it "responds with 404 if user does not exist" do
      sign_in(user1)
      delete "/follow/doesnotexist.json"
      expect(response.status).to eq(404)
      expect(response.parsed_body["errors"]).to include(
        I18n.t("follow.user_not_found", username: "doesnotexist".inspect),
      )
    end
  end

  describe "#posts" do
    before do
      ::Follow::Updater.new(user1, user2).watch_follow
      ::Follow::Updater.new(user1, tl3).watch_follow
    end

    fab!(:post_5) { Fabricate(:post, user: user2, created_at: 20.hours.ago) }
    fab!(:post_4) { Fabricate(:post, user: user2, created_at: 10.hours.ago) }
    fab!(:post_3) { Fabricate(:post, user: user2, created_at: 5.hours.ago) }
    fab!(:post_2) { Fabricate(:post, user: tl3, created_at: 3.hours.ago) }
    fab!(:post_1) { Fabricate(:post, user: user2, topic: post_3.topic, created_at: 2.hours.ago) }
    fab!(:post_by_unfollowed_user, :post)

    it "does not allow non-staff users to access the follow posts feed of other users" do
      sign_in(user1)
      get "/follow/posts/#{user2.username}.json"
      expect(response.status).to eq(403)

      sign_in(user2)
      get "/follow/posts/#{user1.username}.json"
      expect(response.status).to eq(403)

      sign_out
      get "/follow/posts/#{user1.username}.json"
      expect(response.status).to eq(403)
    end

    it "allows staff users to access the follow posts feed of other users" do
      mod = Fabricate(:moderator)
      sign_in(mod)
      get "/follow/posts/#{user1.username}.json"
      expect(response.status).to eq(200)
      expect(response_topic_ids(response)).to eq([post_1, post_2, post_3, post_4, post_5].map(&:id))

      admin = Fabricate(:admin)
      sign_in(admin)
      get "/follow/posts/#{user1.username}.json"
      expect(response.status).to eq(200)
      expect(response_topic_ids(response)).to eq([post_1, post_2, post_3, post_4, post_5].map(&:id))
    end

    it "allows users to see their own follow posts feed" do
      sign_in(user1)
      get "/follow/posts/#{user1.username}.json"
      expect(response.status).to eq(200)
      expect(response_topic_ids(response)).to eq([post_1, post_2, post_3, post_4, post_5].map(&:id))
    end

    it "indicates in the response whether or not there are more posts" do
      sign_in(user1)
      get "/follow/posts/#{user1.username}.json", params: { limit: 2 }
      expect(response.status).to eq(200)
      expect(response_topic_ids(response)).to eq([post_1.id, post_2.id])
      expect(response.parsed_body["extras"]["has_more"]).to eq(true)

      get "/follow/posts/#{user1.username}.json", params: { limit: 5 }
      expect(response.status).to eq(200)
      expect(response_topic_ids(response)).to eq([post_1, post_2, post_3, post_4, post_5].map(&:id))
      expect(response.parsed_body["extras"]["has_more"]).to eq(false)
    end

    it "paginates correctly" do
      sign_in(user1)
      get "/follow/posts/#{user1.username}.json", params: { limit: 2 }
      expect(response.status).to eq(200)
      expect(response_topic_ids(response)).to eq([post_1.id, post_2.id])
      expect(response.parsed_body["extras"]["has_more"]).to eq(true)

      get "/follow/posts/#{user1.username}.json",
          params: {
            limit: 2,
            created_before: post_2.created_at,
          }

      expect(response.status).to eq(200)
      expect(response_topic_ids(response)).to eq([post_3.id, post_4.id])
      expect(response.parsed_body["extras"]["has_more"]).to eq(true)

      get "/follow/posts/#{user1.username}.json",
          params: {
            limit: 2,
            created_before: post_4.created_at,
          }

      expect(response.status).to eq(200)
      expect(response_topic_ids(response)).to eq([post_5.id])
      expect(response.parsed_body["extras"]["has_more"]).to eq(false)
    end

    it "responds with an error if the supplied created_before date is invalid" do
      sign_in(user1)
      get "/follow/posts/#{user1.username}.json", params: { created_before: "sdfsfs" }

      expect(response.status).to eq(400)
      expect(response.parsed_body["errors"]).to contain_exactly(
        I18n.t("follow.invalid_created_before_date", value: "sdfsfs".inspect),
      )
    end

    it "serializes posts with all the attributes that the client needs" do
      sign_in(user1)
      get "/follow/posts/#{user1.username}.json", params: { limit: 1 }
      expect(response.status).to eq(200)
      posts = response.parsed_body["posts"]
      p = response.parsed_body["posts"][0]
      expect(p["excerpt"]).to be_present
      expect(p["category_id"]).to eq(post_1.topic.category.id)
      expect(p["created_at"]).to eq(post_1.created_at.iso8601(3))
      expect(p["id"]).to eq(post_1.id)
      expect(p["post_number"]).to eq(post_1.post_number)
      expect(p["topic_id"]).to eq(post_1.topic.id)
      expect(p["url"]).to eq(post_1.url)

      expect(p["user"]["id"]).to eq(post_1.user.id)
      expect(p["user"]["username"]).to eq(post_1.user.username)
      expect(p["user"]["name"]).to eq(post_1.user.name)
      expect(p["user"]["avatar_template"]).to eq(post_1.user.avatar_template)

      expect(p["topic"]["id"]).to eq(post_1.topic.id)
      expect(p["topic"]["title"]).to eq(post_1.topic.title)
      expect(p["topic"]["fancy_title"]).to eq(post_1.topic.fancy_title)
      expect(p["topic"]["slug"]).to eq(post_1.topic.slug)
      expect(p["topic"]["posts_count"]).to eq(post_1.topic.posts_count)
    end
  end

  describe "#filter" do
    before do
      ::Follow::Updater.new(user1, user2).watch_follow
      ::Follow::Updater.new(user1, tl3).watch_follow
    end

    fab!(:post_5) { Fabricate(:post, user: user2, created_at: 20.hours.ago) }
    fab!(:post_4) { Fabricate(:post, user: user2, created_at: 10.hours.ago) }
    fab!(:post_3) { Fabricate(:post, user: user2, created_at: 5.hours.ago) }
    fab!(:post_2) { Fabricate(:post, user: tl3, created_at: 3.hours.ago) }
    fab!(:post_1) { Fabricate(:post, user: user2, topic: post_3.topic, created_at: 2.hours.ago) }
    fab!(:post_by_unfollowed_user, :post)

    it "allows users to see their own follow posts feed" do
      sign_in(user1)
      get "/follow/posts/#{user1.username}.json"
      expect(response.status).to eq(200)
      topic_ids_from_api = response.parsed_body["posts"].map { |t| t["topic_id"] }.uniq

      get "/filter", params: { q: "following-feed:#{user1.username}", format: :json }
      expect(response.status).to eq(200)
      topic_ids_from_filter = response.parsed_body["topic_list"]["topics"].map { |t| t["id"] }.uniq

      expect(topic_ids_from_api).to match_array(topic_ids_from_filter)
    end

    it "should not allow users to see other users follow posts feed" do
      sign_in(user2)
      get "/follow/posts/#{user1.username}.json"
      expect(response.status).to eq(403)

      get "/filter", params: { q: "following-feed:#{user1.username}", format: :json }
      expect(response.parsed_body["topic_list"]["topics"]).to eq([])
    end

    it "allows staff users to access the follow posts feed of other users" do
      user1_interacted_topics = [
        post_1.topic.id,
        post_2.topic.id,
        post_3.topic.id,
        post_4.topic.id,
        post_5.topic.id,
      ].uniq

      mod = Fabricate(:moderator)
      sign_in(mod)

      get "/filter", params: { q: "following-feed:#{user1.username}", format: :json }
      expect(response.status).to eq(200)
      topic_ids_from_filter = response.parsed_body["topic_list"]["topics"].map { |t| t["id"] }.uniq

      expect(topic_ids_from_filter).to match_array(user1_interacted_topics)

      admin = Fabricate(:admin)
      sign_in(admin)

      get "/filter", params: { q: "following-feed:#{user1.username}", format: :json }
      expect(response.status).to eq(200)
      topic_ids_from_filter = response.parsed_body["topic_list"]["topics"].map { |t| t["id"] }.uniq

      expect(topic_ids_from_filter).to match_array(user1_interacted_topics)
    end
  end
end
