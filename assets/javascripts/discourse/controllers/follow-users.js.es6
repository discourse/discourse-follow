import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  hasUsers: Ember.computed.notEmpty('users'),

  @computed('type')
  noneMessage(type) {
    return `user.${type}.none`;
  }
});
