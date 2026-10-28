# frozen_string_literal: true

describe "Attrs added by the plugin to the UserCardSerializer" do
  fab!(:follower, :user)
  fab!(:followed, :user)
  fab!(:not_followed, :user)
  fab!(:opted_out, :user)

  before do
    SiteSetting.discourse_follow_enabled = true
    SiteSetting.hide_new_user_profiles = false
    Follow::Updater.new(follower, followed).watch_follow
    opted_out.custom_fields["allow_people_to_follow_me"] = false
    opted_out.save!
  end

  def follow_attrs_from_user_cards(users)
    get "/user-cards.json", params: { user_ids: users.map(&:id).join(",") }
    expect(response.status).to eq(200)
    response.parsed_body["users"].to_h do |card|
      [card["id"], card.slice("can_follow", "is_followed")]
    end
  end

  it "returns whether the current user can follow and is following each user" do
    sign_in(follower)

    expect(follow_attrs_from_user_cards([followed, not_followed, opted_out, follower])).to eq(
      followed.id => {
        "can_follow" => true,
        "is_followed" => true,
      },
      not_followed.id => {
        "can_follow" => true,
        "is_followed" => false,
      },
      opted_out.id => {
        "can_follow" => false,
        "is_followed" => false,
      },
      follower.id => {
        "can_follow" => false,
        "is_followed" => false,
      },
    )
  end

  it "returns false for can_follow and is_followed to anonymous users" do
    expect(follow_attrs_from_user_cards([followed, not_followed])).to eq(
      followed.id => {
        "can_follow" => false,
        "is_followed" => false,
      },
      not_followed.id => {
        "can_follow" => false,
        "is_followed" => false,
      },
    )
  end

  it "loads the follow data without a query per user" do
    sign_in(follower)

    one_user_queries = track_sql_queries { follow_attrs_from_user_cards([followed]) }
    four_users_queries =
      track_sql_queries do
        follow_attrs_from_user_cards([followed, not_followed, opted_out, follower])
      end

    # Other plugins can add per-user queries to this route, so only count ours.
    follow_data = /user_followers|user_custom_fields/
    expect(four_users_queries.grep(follow_data).size).to eq(one_user_queries.grep(follow_data).size)
  end
end
