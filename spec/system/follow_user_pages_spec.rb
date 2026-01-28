# frozen_string_literal: true

RSpec.describe "Follow user pages" do
  fab!(:user1, :user)
  fab!(:user2, :user)
  fab!(:user3, :user)
  fab!(:user2_post) { Fabricate(:post, user: user2) }
  let(:everyone_group) { Group[:everyone] }

  before do
    SiteSetting.discourse_follow_enabled = true
    SiteSetting.follow_followers_visible = FollowPagesVisibility::EVERYONE
    SiteSetting.follow_following_visible = FollowPagesVisibility::EVERYONE

    Follow::Updater.new(user1, user2).watch_follow
    Follow::Updater.new(user3, user1).watch_follow
  end

  before { sign_in(user1) }

  it "should allow user to navigate to the follow user profile pages" do
    follow_page = PageObjects::Pages::Follow.new(user1)
    follow_page.visit

    expect(follow_page).to have_following_topic(user2_post.topic)

    follow_page.click_on_followers

    expect(follow_page).to have_follower(user3)

    follow_page.click_on_following

    expect(follow_page).to have_following(user2)
  end
end
