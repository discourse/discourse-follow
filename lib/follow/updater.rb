class Follow::Updater
  def initialize(follower, target)
    @follower = follower
    @target = target
  end
  
  def cycle
    #follow = ActiveModel::Type::Boolean.new.cast(follow)

    target_id = @target.id.to_s
    follower_id = @follower.id.to_s
    followers = @target.followers
    following = @follower.following
    following_ids = @follower.following_ids

    following_entry = @follower.following.find {|e| e[0] == target_id.to_s}
     
    current_follow_level = following_entry ? following_entry[1] : ""
    
    case current_follow_level
      when "0"
        new_following_level = "1"
        notification_level = Follow::Notification.levels[:watching_first_post]
      when "1"
        new_following_level = ""
        notification_level = ""
      else
        new_following_level = "0"
        notification_level = Follow::Notification.levels[:watching]
        # ignore
    end

    case new_following_level
      when ""
        followers.delete(follower_id)
        following = following.select { |f| f[0] != target_id }
      when "0","1"
        followers.push(follower_id) if followers.exclude?(follower_id)

        if following_ids.include?(target_id)
          following.each do |f|
            if f[0] == target_id
              f[1] = notification_level
            end
          end
        else
          following.push([target_id, notification_level])
        end
      else
        # ignore
    end

    @target.custom_fields['followers'] = followers.join(',')
    @follower.custom_fields['following'] = following.map { |f| f.join(',') }

    @target.save_custom_fields(true)
    @follower.save_custom_fields(true)
    
    if ["0","1"].include?new_following_level
      payload = {
        notification_type: Notification.types[:following],
        data: {
          display_username: @follower.username,
          following: true
        }.to_json
      }
      send_notification(payload) if should_notify?(payload)
    end

    new_following_level
  end
  
  def should_notify?(payload)
    SiteSetting.follow_notifications_enabled &&
    @follower.notify_followed_user_when_followed &&
    @target.notify_me_when_followed &&
    !notification_sent_recently(payload)
  end
  
  def send_notification(payload)
    @target.notifications.create!(payload)
  end
  
  def notification_sent_recently(payload)
    @target.notifications.where(payload).where('created_at >= ?', 1.day.ago).exists?
  end
end