require 'rails_helper'

describe ::Follow::Updater do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }

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

end