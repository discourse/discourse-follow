import { action, computed } from "@ember/object";
import { ajax } from 'discourse/lib/ajax';
import I18n from "I18n";
import { isEmpty } from "@ember/utils";
import { NotificationLevels } from "discourse/lib/notification-levels";
import discourseComputed from "discourse-common/utils/decorators";
import getURL from "discourse-common/lib/get-url";
import Component from "@ember/component";
import layout from "select-kit/templates/components/topic-notifications-button";

export default Component.extend({
  layout,
  router: Ember.inject.service('-routing'),
  classNames: ["follow-notifications-button"],
  classNameBindings: ["isLoading"],
  appendReason: true,
  showFullTitle: true,
  notificationLevel: null,
  topic: null,
  showCaret: true,
  isLoading: false,
  icon: computed("isLoading", function () {
    return this.isLoading ? "spinner" : null;
  }),

  init() {
    this._super(...arguments);
    this.set('notificationLevel', parseInt(this.get('user.following_notification_level')));
  },

  actions: {
  changeFollowNotificationLevel(levelId) {
    if (levelId !== this.notificationLevel) {
      let user = this.get('user');

      let following_notification_level = levelId.toString();
      let existingTotal = this.get('user.total_followers');

      this.set('loading', true);

      ajax(`/follow/${user.username}`, {
        type: 'PUT',
        data: {
          following_notification_level
        }
      }).then((result) => {
        if (["3","4"].includes(result.following_notification_level) && !["3","4"].includes(this.notificationLevel.toString())) {
          this.set('user.total_followers', this.user.total_followers + 1);
        };

        if (["","0","1"].includes(result.following_notification_level) && ["3","4"].includes(this.notificationLevel.toString())) {
          this.set('user.total_followers', this.user.total_followers - 1);
        };
        this.set('notificationLevel',parseInt(result.following_notification_level));
      }).finally(() => {
        this.set("isLoading", false);
        let newTotal = this.get('user.total_followers');
        const currentRouteName = this.get("router.router.currentRouteName");

        // refresh if looking at follow
        if (currentRouteName.indexOf('follow') > -1) {
          const followRoute = getOwner(this).lookup(`route:follow`);
          followRoute.refresh();
        }

        // refresh if looking at site discovery && nav item changes
        if ((existingTotal == 0 || newTotal == 0) &&
            currentRouteName.indexOf('discovery') > -1 &&
            currentRouteName.toLowerCase().indexOf('category') === -1) {
          const discoveryRoute = getOwner(this).lookup('route:discovery');
			    discoveryRoute.refresh();
        }
      });
    }
  }},
});