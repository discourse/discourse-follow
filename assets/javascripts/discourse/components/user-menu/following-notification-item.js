import UserMenuNotificationItem from "discourse/components/user-menu/notification-item";
import { userPath } from "discourse/lib/url";
import I18n from "I18n";

export default class UserMenuFollowingNotificationItem extends UserMenuNotificationItem {
  get url() {
    return userPath(this.notification.data.display_username);
  }

  get description() {
    return I18n.t("notifications.following_description");
  }

  get descriptionHtmlSafe() {
    return false;
  }
}
