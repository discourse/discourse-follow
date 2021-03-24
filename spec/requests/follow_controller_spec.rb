# frozen_string_literal: true
require_relative '../plugin_helper'

describe ::Follow::FollowController do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }

  context "lists" do
    before do
      updater = ::Follow::Updater.new(user1, user2)
      updater.update(true)
    end

    it "following" do
      get "/u/#{user1[:username]}/follow/following.json", params: { type: 'following' }

      expect(response.status).to eq(200)
      expect(response.parsed_body[0]['id']).to eq(user2.id)
      expect(response.parsed_body[0]['username']).to eq(user2.username)
    end

    it "followers" do
      get "/u/#{user2[:username]}/follow/followers.json", params: { type: 'followers' }

      expect(response.status).to eq(200)
      expect(response.parsed_body[0]['id']).to eq(user1.id)
      expect(response.parsed_body[0]['username']).to eq(user1.username)
    end
  end

  it "updates followers" do
    sign_in(user1)
    put "/follow/#{user2.username}", params: { follow: true }

    expect(response.status).to eq(200)
    expect(response.parsed_body['following']).to eq(true)
  end
end
