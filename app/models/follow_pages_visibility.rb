# frozen_string_literal: true

class FollowPagesVisibility < EnumSiteSetting
  NO_ONE = "no-one"
  SELF = "self"
  EVERYONE = "everyone"

  class << self
    def valid_value?(val)
      values.any? { |v| v[:value] == val }
    end

    def values
      @values ||=
        [
          NO_ONE,
          SELF,
          "trust_level_4",
          "trust_level_3",
          "trust_level_2",
          "trust_level_1",
          "trust_level_0",
          EVERYONE,
        ].map { |v| { name: "follow.follow_pages_visibility.#{v}", value: v } }
    end

    def translate_names?
      true
    end

    def can_see_followers_page?(user:, target_user:)
      can_see_page?(user, target_user, SiteSetting.follow_followers_visible)
    end

    def can_see_following_page?(user:, target_user:)
      can_see_page?(user, target_user, SiteSetting.follow_following_visible)
    end

    private

    def can_see_page?(user, target_user, page_setting_value)
      return false if !SiteSetting.discourse_follow_enabled
      return false if target_user.blank?
      return true if page_setting_value == EVERYONE
      return false if page_setting_value == NO_ONE
      return false if user.blank?
      return true if user.id == target_user.id
      return false if page_setting_value == SELF
      group = Group.lookup_group(page_setting_value.to_sym)
      return false if group.blank?
      GroupUser.where(user_id: user.id, group_id: group.id).exists?
    end
  end
end
