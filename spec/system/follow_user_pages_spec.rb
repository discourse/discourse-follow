# frozen_string_literal: true

RSpec.describe "Follow user pages", type: :system, js: true do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }
  fab!(:user2_post) { Fabricate(:post, user: user2) }
  let(:everyone_group) { Group[:everyone] }

  before do
    SiteSetting.discourse_follow_enabled = true
    SiteSetting.follow_followers_visible = FollowPagesVisibility::EVERYONE
    SiteSetting.follow_following_visible = FollowPagesVisibility::EVERYONE

    Follow::Updater.new(user1, user2).watch_follow
    Follow::Updater.new(user3, user1).watch_follow
  end

  describe "when user has redesigned user page navigation enabled" do
    before do
      everyone_group.add(user1)
      SiteSetting.enable_new_user_profile_nav_groups = everyone_group.name
      sign_in(user1)
    end

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
end
