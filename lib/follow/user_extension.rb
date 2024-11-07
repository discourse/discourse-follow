# frozen_string_literal: true

module Follow::UserExtension
  def self.prepended(base)
    base.has_many :follower_relations, class_name: "UserFollower", dependent: :delete_all
    base.has_many :followers,
                  ->(user) do
                    if !user.allow_people_to_follow_me || user.user_option&.hide_profile
                      where("1=0")
                    end
                  end,
                  through: :follower_relations,
                  source: :follower_user

    base.has_many :following_relations,
                  class_name: "UserFollower",
                  foreign_key: :follower_id,
                  dependent: :delete_all
    base.has_many :following,
                  -> { UserFollower.filter_opted_out_users(self) },
                  through: :following_relations,
                  source: :followed_user
  end
end
