class Follow::FollowingMigration
  def self.transform_user_arrays
    p "====================================================="
    p "|                                                   |"
    p "| FOLLOW PLUGIN:  Starting following data migration |"
    p "|                                                   |"
    p "====================================================="
    p "                                                     "
    
    User.find_each do |u|
      if u.following.count > 0
        u.custom_fields["following"] = convert_to_simple_array(u.custom_fields["following"])
        u.save_custom_fields(true)
      end
    end
    p "====================================================="
    p "|                                                   |"
    p "| FOLLOW PLUGIN: Completed following data migration |"
    p "|                                                   |"
    p "====================================================="
  end

  def self.convert_to_simple_array(this_array)
    new_array = []
    this_array.each do |entry|
      new_array.push(entry.split(',')[0])
    end
    new_array
  end
end
