# frozen_string_literal: true
# converts legacy following array of array (e.g. [[1, 2], [3, 3], [5, 4]]) to simpler array (e.g. [1,2,5]) to ensure sites are compatible with refactored code.

desc "Converts legacy following data format to new, simpler format"
task "follow:following_refactor_transform" => :environment do
  Follow::FollowingMigration.transform_user_arrays
end
