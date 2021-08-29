import NotificationsButtonComponent from "select-kit/components/notifications-button";
import { computed } from "@ember/object";
import { followLevels } from "../lib/follow-notification-levels";

export default NotificationsButtonComponent.extend({
  pluginApiIdentifiers: ["follow-notifications-options"],
  classNames: ["follow-notifications-options"],
  content: followLevels,

  selectKitOptions: {
    i18nPrefix: "user.following_level",
    showFullTitle: true,
    showCaret: false,
  },

});

  // @computed('user', 'currentUser')
  // isHidden(user, currentUser) {
  //   return currentUser && currentUser.username !== user.username;
  // },
