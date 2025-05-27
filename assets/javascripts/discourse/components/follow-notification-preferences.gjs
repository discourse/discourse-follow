import Component from "@ember/component";
import { observes } from "@ember-decorators/object";
import PreferenceCheckbox from "discourse/components/preference-checkbox";
import { i18n } from "discourse-i18n";

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

  <template>
    <div class="control-group follow-notifications">
      <label class="control-label">{{i18n "user.follow.label"}}</label>

      <div class="controls">
        <PreferenceCheckbox
          @labelKey="user.follow_notifications_options.allow_people_to_follow_me"
          @checked={{this.user.allow_people_to_follow_me}}
          class="pref-allow-people-to-follow-me"
        />

        <PreferenceCheckbox
          @labelKey="user.follow_notifications_options.notify_me_when_followed"
          @checked={{this.user.notify_me_when_followed}}
          class="pref-notify-me-when-followed"
        />

        <PreferenceCheckbox
          @labelKey="user.follow_notifications_options.notify_followed_user_when_followed"
          @checked={{this.user.notify_followed_user_when_followed}}
          class="pref-notify-followed-user-when-followed"
        />

        <PreferenceCheckbox
          @labelKey="user.follow_notifications_options.notify_me_when_followed_replies"
          @checked={{this.user.notify_me_when_followed_replies}}
          class="pref-notify-me-when-followed-replies"
        />

        <PreferenceCheckbox
          @labelKey="user.follow_notifications_options.notify_me_when_followed_creates_topic"
          @checked={{this.user.notify_me_when_followed_creates_topic}}
          class="pref-notify-me-when-followed-creates-topic"
        />
      </div>
    </div>
  </template>
}
