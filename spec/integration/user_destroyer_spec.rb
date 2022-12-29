# frozen_string_literal: true

require "rails_helper"

describe "User destroyer with the follow plugin" do
  let(:user_a) { Fabricate(:user) }
  let(:user_b) { Fabricate(:user) }
  let(:user_c) { Fabricate(:user) }

  before do
    SiteSetting.discourse_follow_enabled = true
    Jobs.run_immediately!
    Follow::Updater.new(user_a, user_b).watch_follow
    Follow::Updater.new(user_c, user_a).watch_follow
  end

  it "deletes all the follower and following relationships of the user being deleted" do
    UserDestroyer.new(Discourse.system_user).destroy(user_a)
    user_b.reload
    user_c.reload
    expect(user_b.id).to be_present
    expect(user_c.id).to be_present
    expect(user_b.follower_relations.count).to eq(0)
    expect(user_c.following_relations.count).to eq(0)
  end
end
