# frozen_string_literal: true

module Follow::GuardianExtension
  def can_follow?(target)
    return false if !authenticated?
    return false if target.id == user.id
    return false if target.bot?
    return false if target.staged?
    return false if target.suspended?
    return false if !target.allow_people_to_follow_me
    return false if target.user_option&.hide_profile
    true
  end
end
