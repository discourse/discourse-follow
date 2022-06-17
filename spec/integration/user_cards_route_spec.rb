# frozen_string_literal: true

require 'rails_helper'

describe "Attrs added by the plugin to the UserCardSerializer" do
  fab!(:follower) { Fabricate(:user) }
  fab!(:followed) { Fabricate(:user) }

  before do
    SiteSetting.discourse_follow_enabled = true
    Follow::Updater.new(follower, followed).watch_follow
    sign_in(follower)
  end

  it "do not break the /user-cards.json route" do
    get "/user-cards.json", params: { user_ids: [followed.id].join(",") }
    expect(response.status).to eq(200)
  end
end
