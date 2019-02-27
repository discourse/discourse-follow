import NavItem from 'discourse/models/nav-item';
import { withPluginApi } from 'discourse/lib/plugin-api';
import { default as computed } from 'ember-addons/ember-computed-decorators';
import { replaceIcon } from 'discourse-common/lib/icon-library';
import { userPath } from "discourse/lib/url";

export default {
  name: 'follow-edits',
  initialize(container) {
    const currentUser = container.lookup("current-user:main");
    const siteSettings = container.lookup("site-settings:main");

    if (!siteSettings.discourse_follow_enabled) return;

    NavItem.reopenClass({
      buildList(category, args) {
        let items = this._super(category, args);

        items = items.reject((item) => item.name === 'following' );

        if (!category && currentUser && currentUser.total_following > 0) {
          items.push(NavItem.fromText('following', args));
        }

        return items;
      }
    });

    const FOLLOWING_TYPE = 800;

    withPluginApi('0.8.13', api => {
      api.modifyClass('route:discovery', {
        actions: {
          refresh() {
            this.refresh();
          }
        }
      });

      api.reopenWidget('notification-item', {
        description() {
          const data = this.attrs.data;
          if (data.following) {
            return I18n.t('notifications.following_description');
          }
          return this._super();
        },

        url() {
          const attrs = this.attrs;
          const data = attrs.data;

          if (attrs.notification_type === FOLLOWING_TYPE) {
            return userPath(data.display_username);
          }

          return this._super();
        }
      });
    });

    replaceIcon('notification.following', 'user-friends')
    replaceIcon('notification.following_posted', 'user-friends')
  }
}
