# frozen_string_literal: true
# converts legacy following array (e.g. ["1,0", "3,1", "5,0"]) to new array (e.g. ["1,3", "3,4", "5,3"]) to ensure sites are compatible with new watching/watching first post distinction.

desc "Converts legacy following data format to new format"
task "follow:following_update_transform" => :environment do
  Follow::FollowingMigration.transform_user_following_arrays
end
