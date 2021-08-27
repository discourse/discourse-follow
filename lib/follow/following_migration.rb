class Follow::FollowingMigration
  def self.transform_user_arrays
    User.find_each do |u|
      if u.following.count > 0
        u.custom_fields["following"] = convert_to_simple_array(u.following)
        byebug
      end
    end
    p "Completed following migration"
  end

  def self.convert_to_simple_array(this_array)
    this_array.reduce([]) do |new_list, item|
      if item.is_a? Integer
        this = item
      else
        this = item [0]
      end
      new_list.push(this)
    end
  end
end