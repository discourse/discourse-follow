import NavItem from 'discourse/models/nav-item';
import { withPluginApi } from 'discourse/lib/plugin-api';
import { default as computed } from 'ember-addons/ember-computed-decorators';
import { replaceIcon } from 'discourse-common/lib/icon-library';

export default {
  name: 'follow-edits',
  initialize(container) {
    const currentUser = container.lookup("current-user:main");

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
    });

    replaceIcon('notification.following', 'user')
  }
}
