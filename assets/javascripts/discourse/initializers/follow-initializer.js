import { withPluginApi } from "discourse/lib/plugin-api";
import { userPath } from "discourse/lib/url";
import I18n from "I18n";

export default {
  name: "follow-plugin-initializer",
  initialize(/*container*/) {
    withPluginApi("0.8.10", (api) => {
      const currentUser = api.getCurrentUser();
      if (!currentUser) {
        return;
      }
      api.replaceIcon(
        "notification.following",
        "discourse-follow-new-follower"
      );
      api.replaceIcon(
        "notification.following_created_topic",
        "discourse-follow-new-topic"
      );
      api.replaceIcon(
        "notification.following_replied",
        "discourse-follow-new-reply"
      );

      if (api.registerNotificationTypeRenderer) {
        api.registerNotificationTypeRenderer(
          "following",
          (NotificationTypeBase) => {
            return class extends NotificationTypeBase {
              get linkTitle() {
                return I18n.t("notifications.titles.following");
              }

              get linkHref() {
                return userPath(this.notification.data.display_username);
              }

              get icon() {
                return "discourse-follow-new-follower";
              }

              get label() {
                return this.notification.data.display_username;
              }

              get description() {
                return I18n.t("notifications.following_description", {});
              }
            };
          }
        );
      }

      // workaround to make core save custom fields when changing
      // preferences
      api.modifyClass("controller:preferences/notifications", {
        pluginId: "discourse-follow-notification-preference",

        actions: {
          save() {
            if (!this.saveAttrNames.includes("custom_fields")) {
              this.saveAttrNames.push("custom_fields");
            }
            this._super(...arguments);
          },
        },
      });
    });
  },
};
