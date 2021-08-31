import { default as computed, observes, on } from 'discourse-common/utils/decorators';

export default Ember.Component.extend({
  router: Ember.inject.service('-routing'),
  classNames: 'follow-selector-container',
  tagName: 'li',

  @computed('user', 'currentUser')
  showToggle(user, currentUser) {
    return currentUser && currentUser.username !== user.username;
  },

})
