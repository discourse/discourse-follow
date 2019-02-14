import { ajax } from 'discourse/lib/ajax';
import { default as computed, observes, on } from 'ember-addons/ember-computed-decorators';
import { getOwner } from 'discourse-common/lib/get-owner';

export default Ember.Component.extend({
  router: Ember.inject.service('-routing'),
  classNames: 'follow-toggle',

  @computed('user.following')
  label(following) {
    return following ? "user.unfollow" : "user.follow";
  },

  @computed('user.following')
  icon(following) {
    return following ? "user-minus" : "user-plus";
  },

  @computed('user.following')
  classes(following) {
    return following ? "btn-primary" : '';
  },

  @computed('user', 'currentUser')
  showToggle(user, currentUser) {
    return currentUser && currentUser.username !== user.username;
  },

  actions: {
    follow() {
      let user = this.get('user');
      this.set('loading', true);
      ajax(`/follow/${user.username}`, {
        type: 'PUT',
        data: {
          follow: !user.following
        }
      }).then((result) => {
        this.set('user.following', result.following);
      }).finally(() => {
        this.set('loading', false);
        const currentRouteName = this.get("router.router.currentRouteName");
        if (currentRouteName.indexOf('follow') > -1) {
          const currentRouteInstance = getOwner(this).lookup(`route:follow`);
          currentRouteInstance.refresh();
        }
      })
    }
  }
})
