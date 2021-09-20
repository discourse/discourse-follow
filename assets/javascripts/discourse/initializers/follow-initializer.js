import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "follow-plugin-initializer",
  initialize(/*container*/) {
    withPluginApi("0.8.10", (api) => {
      const currentUser = api.getCurrentUser();
      if (!currentUser) {
        return;
      }
      api.addNavigationBarItem({
        name: "following",
        href: "/following",
        customFilter(category, args /*, router*/) {
          return !category && !args.tagId;
        },
      });
      api.replaceIcon("notification.following", "user-friends");
      api.replaceIcon("notification.following_created_topic", "user-friends");
      api.replaceIcon("notification.following_replied", "user-friends");
    });
  },
};
