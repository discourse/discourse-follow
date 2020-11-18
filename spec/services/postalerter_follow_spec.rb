require 'rails_helper'

describe ::Follow::Updater do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }

  it "sent a notification for original poster and replier" do
    updater = ::Follow::Updater.new(user3, user1)
    updater.update(true)
  
    updater = ::Follow::Updater.new(user3, user2)
    updater.update(true)
    
    first_post = Fabricate(:post, topic: topic, user: user1)
    PostAlerter.post_created(first_post)
    expect(user3.notifications.where('notification_type = 801').where('created_at >= ?', 1.day.ago).exists?).to eq(true)
   
    second_post = Fabricate(:post, topic: topic, user: user2)
    PostAlerter.post_created(second_post)
    expect(user3.notifications.where('notification_type = 802').where('created_at >= ?', 1.day.ago).exists?).to eq(true)
  end
end
