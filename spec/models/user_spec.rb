# frozen_string_literal: true

require "rails_helper"

describe User do
  fab!(:followed1) { Fabricate(:user) }
  fab!(:followed2) { Fabricate(:user) }
  fab!(:follower1) { Fabricate(:user) }
  fab!(:follower2) { Fabricate(:user) }

  before do
    SiteSetting.discourse_follow_enabled = true
    [followed1, followed2].each do |followed|
      [follower1, follower2].each do |follower|
        Follow::Updater.new(follower, followed).watch_follow
      end
    end
  end

  describe "#followers" do
    it "returns followers" do
      expect(followed1.followers.pluck(:id)).to contain_exactly(follower1.id, follower2.id)
      expect(followed2.followers.pluck(:id)).to contain_exactly(follower1.id, follower2.id)

      expect(follower1.followers.pluck(:id)).to be_empty
      expect(follower2.followers.pluck(:id)).to be_empty
    end

    it "returns empty relation if the user has disabled follows" do
      followed1.custom_fields["allow_people_to_follow_me"] = false
      followed1.save!
      expect(followed1.followers.pluck(:id)).to be_empty
      expect(followed2.followers.pluck(:id)).to contain_exactly(follower1.id, follower2.id)
    end

    it "returns empty relation if the user has hidden their profile" do
      followed1.user_option.update!(hide_profile_and_presence: true)
      expect(followed1.followers.pluck(:id)).to be_empty
      expect(followed2.followers.pluck(:id)).to contain_exactly(follower1.id, follower2.id)
    end

    it "returns empty relation if the default_allow_people_to_follow_me setting " \
    "is false and the user has no explicit preference" do
      SiteSetting.default_allow_people_to_follow_me = false
      expect(followed1.followers.pluck(:id)).to be_empty
      expect(followed2.followers.pluck(:id)).to be_empty

      followed1.custom_fields["allow_people_to_follow_me"] = true
      followed1.save!
      expect(followed1.followers.pluck(:id)).to contain_exactly(follower1.id, follower2.id)
      expect(followed2.followers.pluck(:id)).to be_empty
    end
  end

  describe "#following" do
    it "returns followed users" do
      expect(follower1.following.pluck(:id)).to contain_exactly(followed1.id, followed2.id)
      expect(follower2.following.pluck(:id)).to contain_exactly(followed1.id, followed2.id)

      expect(followed1.following.pluck(:id)).to be_empty
      expect(followed2.following.pluck(:id)).to be_empty
    end

    it "excludes users who have disabled follows" do
      followed1.custom_fields["allow_people_to_follow_me"] = false
      followed1.save!

      expect(follower1.following.pluck(:id)).to contain_exactly(followed2.id)
      expect(follower2.following.pluck(:id)).to contain_exactly(followed2.id)
    end

    it "excludes users who have hidden their profile" do
      followed1.user_option.update!(hide_profile_and_presence: true)

      expect(follower1.following.pluck(:id)).to contain_exactly(followed2.id)
      expect(follower2.following.pluck(:id)).to contain_exactly(followed2.id)
    end

    it "excludes users who do not have an explicit preference and the " \
    "default_allow_people_to_follow_me setting is false" do
      SiteSetting.default_allow_people_to_follow_me = false
      expect(follower1.following.pluck(:id)).to be_empty
      expect(follower2.following.pluck(:id)).to be_empty

      followed1.custom_fields["allow_people_to_follow_me"] = true
      followed1.save!

      expect(follower1.following.pluck(:id)).to contain_exactly(followed1.id)
      expect(follower2.following.pluck(:id)).to contain_exactly(followed1.id)
    end
  end
end
