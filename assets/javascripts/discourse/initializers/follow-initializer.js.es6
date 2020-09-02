import NavItem from 'discourse/models/nav-item';
import { withPluginApi } from 'discourse/lib/plugin-api';
import { replaceIcon } from 'discourse-common/lib/icon-library';

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

    withPluginApi('0.8.13', api => {
      api.modifyClass('route:discovery', {
        actions: {
          refresh() {
            this.refresh();
          }
        }
      });
      
      api.modifyClass("controller:preferences/notifications", {
        actions: {
          save() {
            const custom_settings = [
              'notify_me_when_followed',
              'notify_followed_user_when_followed',
              'notify_me_when_followed_replies',
              'notify_me_when_followed_posts'
            ];

            custom_settings.forEach( setting => {
              this.set(`model.custom_fields.${setting}`, this.get(`model.${setting}`))
            });

            this.get("saveAttrNames").push("custom_fields")
            this._super();
          }
        }
      })
    });

    replaceIcon('notification.following', 'user-friends');
    replaceIcon('notification.following_posted', 'user-friends');
    replaceIcon('notification.following_replied', 'user-friends');
  }
};
