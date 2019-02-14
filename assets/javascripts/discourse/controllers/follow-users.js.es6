import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  hasUsers: Ember.computed.notEmpty('users'),

  @computed('viewing')
  viewingSelf(viewing) {
    return viewing === this.get('currentUser.username');
  },

  @computed('type', 'viewingSelf')
  noneMessage(type, viewingSelf) {
    let key = viewingSelf ? 'none' : 'none_other';
    return `user.${type}.${key}`;
  }
});
