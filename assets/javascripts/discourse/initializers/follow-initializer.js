import { action } from "@ember/object";
import { withPluginApi } from "discourse/lib/plugin-api";
import { VALUE_TRANSFORMERS } from "discourse/lib/transformer/registry";
import { userPath } from "discourse/lib/url";
import { i18n } from "discourse-i18n";

export default {
  name: "follow-plugin-initializer",
  initialize(/*container*/) {
    withPluginApi((api) => {
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
                return i18n("notifications.titles.following");
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
                return i18n("notifications.following_description", {});
              }
            };
          }
        );
      }

      // Add custom_fields to the notifications page save attributes
      if (VALUE_TRANSFORMERS.includes("preferences-save-attributes")) {
        api.registerValueTransformer(
          "preferences-save-attributes",
          ({ value: attrs, context }) => {
            if (context.page === "notifications") {
              attrs.push("custom_fields");
            }
            return attrs;
          }
        );
      } else {
        // Backward compatibility for older Discourse versions
        api.modifyClass(
          "controller:preferences/notifications",
          (Superclass) =>
            class extends Superclass {
              @action
              save() {
                if (!this.saveAttrNames.includes("custom_fields")) {
                  this.saveAttrNames.push("custom_fields");
                }
                super.save();
              }
            }
        );
      }
    });
  },
};
