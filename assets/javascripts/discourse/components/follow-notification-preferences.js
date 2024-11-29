import Component from "@ember/component";
import { observes } from "@ember-decorators/object";

const preferences = [
  "notify_me_when_followed",
  "notify_followed_user_when_followed",
  "notify_me_when_followed_replies",
  "notify_me_when_followed_creates_topic",
  "allow_people_to_follow_me",
];

export default class FollowNotificationPreferences extends Component {
  @observes(...preferences.map((p) => `user.${p}`))
  _updatePreferences() {
    if (!this.user.custom_fields) {
      this.user.set("custom_fields", {});
    }
    preferences.forEach((p) => {
      this.user.set(`custom_fields.${p}`, this.user[p]);
    });
  }
}
