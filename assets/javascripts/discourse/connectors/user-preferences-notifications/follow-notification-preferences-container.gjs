import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import FollowNotificationPreferences from "../../components/follow-notification-preferences";

@tagName("div")
@classNames(
  "user-preferences-notifications-outlet",
  "follow-notification-preferences-container"
)
export default class FollowNotificationPreferencesContainer extends Component {
  static shouldRender(_, context) {
    return context.siteSettings.follow_notifications_enabled;
  }

  <template><FollowNotificationPreferences @user={{this.model}} /></template>
}
