import { ajax } from 'discourse/lib/ajax';
import { default as computed, observes, on } from 'discourse-common/utils/decorators';
import { getOwner } from 'discourse-common/lib/get-owner';

export default Ember.Component.extend({
  router: Ember.inject.service('-routing'),
  classNames: 'follow-toggle',
  tagName: 'li',

  @computed('user.following')
  label(following) {
    switch(following)
    {
      case "":
        return "user.following_level.not_following.label";
      case "0":
        return "user.following_level.watching.label";
      case "1":
        return "user.following_level.watching_first_post.label";
      default:
        return "user.following_level.not_following.label";
    }
  },

  @computed('user.following')
  icon(following) {
    switch(following)
    {
      case "":
        return "user-plus";
      case "0":
        return "user-check";
      case "1":
        return "user-check";
      default:
        return "user-plus";
    }
  },

  @computed('user', 'currentUser')
  showToggle(user, currentUser) {
    return currentUser && currentUser.username !== user.username;
  },

  actions: {
    follow() {
      let user = this.get('user');
      let follow = "cycle";

      this.set('loading', true);

      ajax(`/follow/${user.username}`, {
        type: 'PUT',
        data: {
          follow
        }
      }).then((result) => {
        this.set('user.following', result.follow_level);
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
