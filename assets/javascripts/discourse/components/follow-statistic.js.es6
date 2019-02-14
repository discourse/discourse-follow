import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'follow-statistic',

  init() {
    this._super();
    this.set('tagName', this.get('isCard') ? 'h3' : 'div');
  },

  didInsertElement() {
    Ember.run.scheduleOnce('afterRender', () => {
      let parent = this.get('isCard') ? '.card-content .metadata' : '.user-main .secondary dl';
      this.$().prependTo(parent);
    });
  },

  @computed('context')
  isCard(context) {
    return context === 'card';
  }
})
