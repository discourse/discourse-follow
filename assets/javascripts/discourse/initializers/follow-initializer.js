import { withPluginApi } from "discourse/lib/plugin-api";

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
