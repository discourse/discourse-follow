import { createWidgetFrom } from "discourse/widgets/widget";
import { DefaultNotificationItem } from "discourse/widgets/default-notification-item";
import { userPath } from "discourse/lib/url";

createWidgetFrom(
  DefaultNotificationItem,
  "following-notification-item",
  {
    description() {
      return I18n.t('notifications.following_description');
    },

    url(data) {
      return userPath(data.display_username);
    }
  }
);
