  ## User Destroyer
  ## There is no DiscourseEvent that fires before UserCustomFields are destroyed
  
  module UserDestroyerFollowerExtension
    protected def prepare_for_destroy(user)
      if SiteSetting.discourse_follow_enabled
        if user.following_ids.present?
          user.following_ids.each do |user_id|
            if following = User.find_by(id: user_id)
              updater = Follow::Updater.new(user, following)
              updater.update(false)
            end
          end
        end
        if user.followers.present? && 
          user.followers.each do |user_id|
            if follower = User.find_by(id: user_id)
              updater = Follow::Updater.new(follower, user)
              updater.update(false)
            end
          end
        end
      end
      super(user)
    end
  end
  
  class ::UserDestroyer
    prepend UserDestroyerFollowerExtension
  end
