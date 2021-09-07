class Follow::FollowingMigration
  def self.transform_user_following_arrays
    p "====================================================="
    p "|                                                   |"
    p "| FOLLOW PLUGIN:  Starting following data migration |"
    p "|                                                   |"
    p "====================================================="
    p "                                                     "

    User.find_each do |u|
      if u.following.count > 0
        u.custom_fields["following"] = update_notification_levels(u.custom_fields["following"])
        u.save_custom_fields(true)
      end
    end

    SiteSetting.follow_following_data_migration = false
    
    p "====================================================="
    p "|                                                   |"
    p "| FOLLOW PLUGIN: Completed following data migration |"
    p "|                                                   |"
    p "====================================================="
  end

  def self.update_notification_levels(custom_field_value)
    
    this_array = Array(custom_field_value)
    new_array = []
    this_array.each do |entry|
      little_array = entry.split(",")
      if little_array[1] == "0"
        little_array[1] = "3"
      elsif little_array[1] == "1"
        little_array[1] = "4"
      end
      new_array.push(little_array.join(','))
    end
    new_array
  end
end
