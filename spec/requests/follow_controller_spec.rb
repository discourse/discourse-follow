require 'rails_helper'

describe ::Follow::FollowController do

  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }

  it "works" do
    updater = ::Follow::Updater.new(user1, user2)
    updater.update(true)

    get "/u/#{user1[:username]}/follow/following.json", :params => { :type => 'following' }

    json = ::JSON.parse(response.body)

    expect(json[0]['id']).to eq(user2.id)
    expect(json[0]['username']).to eq(user2.username)

    get "/u/#{user2[:username]}/follow/followers.json", :params => { :type => 'followers' }

    json = ::JSON.parse(response.body)

    expect(json[0]['id']).to eq(user1.id)
    expect(json[0]['username']).to eq(user1.username)
  end
end
