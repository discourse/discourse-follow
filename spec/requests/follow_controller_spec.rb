# frozen_string_literal: true

require "rails_helper"

describe Follow::FollowController do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:tl4) { Fabricate(:user, trust_level: TrustLevel[4]) }
  fab!(:tl3) { Fabricate(:user, trust_level: TrustLevel[3]) }
  fab!(:tl2) { Fabricate(:user, trust_level: TrustLevel[2]) }

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

  ["followers", "following"].each do |type|
    describe "#list_#{type}" do
      before do
        ::Follow::Updater.new(user1, user2).watch_follow
        ::Follow::Updater.new(user2, user1).watch_follow
      end

      context "when follow_#{type}_visible setting is set to no-one" do
        before do
          SiteSetting.public_send("follow_#{type}_visible=", FollowPagesVisibility::NO_ONE)
        end

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
      expect(response.parsed_body["errors"]).to include(I18n.t("follow.user_not_found", username: "doesnotexist".inspect))
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
      expect(response.parsed_body["errors"]).to include(I18n.t("follow.user_not_found", username: "doesnotexist".inspect))
    end
  end
end
