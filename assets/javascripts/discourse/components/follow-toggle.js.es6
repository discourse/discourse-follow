import { ajax } from 'discourse/lib/ajax';
import { default as computed, observes, on } from 'discourse-common/utils/decorators';
import { getOwner } from 'discourse-common/lib/get-owner';

export default Ember.Component.extend({
  router: Ember.inject.service('-routing'),
  classNames: 'follow-toggle',
  tagName: 'li',

  @computed('user.following')
  label(following) {
    return following ? "user.following.label" : "user.follow.label";
  },

  @computed('user.following')
  icon(following) {
    return following ? "user-check" : "user-plus";
  },

  @computed('user', 'currentUser')
  showToggle(user, currentUser) {
    return currentUser && currentUser.username !== user.username;
  },

  actions: {
    follow() {
      let user = this.get('user');
      let follow = !user.following;

      this.set('loading', true);

      ajax(`/follow/${user.username}`, {
        type: 'PUT',
        data: {
          follow
        }
      }).then((result) => {
        this.set('user.following', result.following);
      }).finally(() => {
        this.set('loading', false);

        let existingTotal = this.currentUser.total_following;
        let changeTotal = follow ? 1 : -1;
        let newTotal = existingTotal + changeTotal;

        this.currentUser.set('total_following', newTotal);

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
      })
    }
  }
})
