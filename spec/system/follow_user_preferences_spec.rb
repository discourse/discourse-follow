# frozen_string_literal: true

RSpec.describe "Follow user preferences", type: :system, js: true do
  fab!(:user)

  before do
    SiteSetting.discourse_follow_enabled = true
    sign_in(user)
  end

  it "should allow user to modify preferences" do
    visit("/u/#{user.username}/preferences/notifications")

    expect(user.custom_fields["allow_people_to_follow_me"]).to eq(nil)

    checkbox1 = page.find(".pref-allow-people-to-follow-me input")
    expect(checkbox1).to be_checked

    checkbox1.click
    page.find(".save-changes").click
    expect(page).to have_content(I18n.t("js.saved"))

    # Navigate away
    visit("/latest")

    # Come back to user preferences and check that the checkbox is now unchecked
    visit("/u/#{user.username}/preferences/notifications")

    checkbox1 = page.find(".pref-allow-people-to-follow-me input")
    expect(checkbox1).not_to be_checked

    expect(user.reload.custom_fields["allow_people_to_follow_me"]).to eq("false")
  end
end
