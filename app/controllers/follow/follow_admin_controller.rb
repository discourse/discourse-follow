class  Follow::FollowAdminController < ::Admin::AdminController
  before_action :ensure_admin

  def delete_notifications
      Notification.where(notification_type: [800,801,802]).find_each do |follow_notification|
        follow_notification.destroy
      end
      render json: success_json
  end
end
