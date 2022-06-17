# frozen_string_literal: true

require "rails_helper"

describe FollowPagesVisibility do
  fab!(:user) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:admin) }
  fab!(:tl0) { Fabricate(:user, trust_level: TrustLevel[0]) }
  fab!(:tl1) { Fabricate(:user, trust_level: TrustLevel[1]) }
  fab!(:tl2) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:tl3) { Fabricate(:user, trust_level: TrustLevel[3]) }
  fab!(:tl4) { Fabricate(:user, trust_level: TrustLevel[4]) }

  before do
    SiteSetting.discourse_follow_enabled = true
    Group.refresh_automatic_groups!
  end

  context "site settings validations" do
    it "prevent unknown values" do
      expect do
        SiteSetting.follow_following_visible = "blah"
      end.to raise_error(Discourse::InvalidParameters) do |error|
        expect(error.message).to include("blah")
        expect(error.message).to include("follow_following_visible")
      end
      expect do
        SiteSetting.follow_followers_visible = "ggg"
      end.to raise_error(Discourse::InvalidParameters) do |error|
        expect(error.message).to include("ggg")
        expect(error.message).to include("follow_followers_visible")
      end
    end

    it "accept good values" do
      # no errors should be raised
      SiteSetting.follow_following_visible = FollowPagesVisibility::NO_ONE
      SiteSetting.follow_followers_visible = FollowPagesVisibility::EVERYONE
      SiteSetting.follow_following_visible = "trust_level_0"
      SiteSetting.follow_followers_visible = "trust_level_1"
    end
  end

  [
    ["can_see_following_page?", "follow_following_visible"],
    ["can_see_followers_page?", "follow_followers_visible"],
  ].each do |(method, setting)|
    describe ".#{method}" do
      context "when the follow_following_visible site setting allows everyone" do
        before do
          SiteSetting.public_send("#{setting}=", FollowPagesVisibility::EVERYONE)
        end

        it "trust level 0 user is allowed to see the page" do
          expect(described_class.public_send(method, user: tl0, target_user: user)).to eq(true)
        end

        it "anon user is allowed to see the page" do
          expect(described_class.public_send(method, user: nil, target_user: user)).to eq(true)
        end
      end

      context "when the follow_following_visible site setting does not allow anyone" do
        before do
          SiteSetting.public_send("#{setting}=", FollowPagesVisibility::NO_ONE)
        end

        it "admin user is not allowed to see the page" do
          expect(described_class.public_send(method, user: admin, target_user: user)).to eq(false)
        end

        it "anon user is not allowed to see the page" do
          expect(described_class.public_send(method, user: nil, target_user: user)).to eq(false)
        end

        it "tl4 user is not allowed to see the page" do
          expect(described_class.public_send(method, user: tl4, target_user: user)).to eq(false)
        end
      end

      context "when the follow_following_visible site setting allows users " \
      "to see their own pages only" do
        before do
          SiteSetting.public_send("#{setting}=", FollowPagesVisibility::SELF)
        end

        it "admin user is not allowed to see the page of other users" do
          expect(described_class.public_send(method, user: admin, target_user: user)).to eq(false)
        end

        it "admin user is allowed to see their own page" do
          expect(described_class.public_send(method, user: admin, target_user: admin)).to eq(true)
        end

        it "anon user is not allowed to see any page" do
          expect(described_class.public_send(method, user: nil, target_user: user)).to eq(false)
          expect(described_class.public_send(method, user: nil, target_user: nil)).to eq(false)
        end

        it "tl4 user is not allowed to see the page of other users" do
          expect(described_class.public_send(method, user: tl4, target_user: user)).to eq(false)
        end

        it "tl4 user is allowed to see their own page" do
          expect(described_class.public_send(method, user: tl4, target_user: tl4)).to eq(true)
        end
      end

      context "when the follow_following_visible site setting allows users " \
      "of specific trust level group" do
        before do
          SiteSetting.public_send("#{setting}=", "trust_level_3")
        end

        it "user in that group is allowed to see their own page" do
          expect(described_class.public_send(method, user: tl4, target_user: tl4)).to eq(true)
          expect(described_class.public_send(method, user: tl3, target_user: tl3)).to eq(true)
        end

        it "user in that group is allowed to see other users pages" do
          expect(described_class.public_send(method, user: tl4, target_user: tl2)).to eq(true)
          expect(described_class.public_send(method, user: tl3, target_user: tl2)).to eq(true)
        end

        it "user not in that group is not allowed to see other users pages" do
          expect(described_class.public_send(method, user: tl2, target_user: tl3)).to eq(false)
          expect(described_class.public_send(method, user: tl2, target_user: tl4)).to eq(false)
        end

        it "user not in that group is allowed to see their own pages" do
          expect(described_class.public_send(method, user: tl2, target_user: tl2)).to eq(true)
        end
      end
    end
  end
end
