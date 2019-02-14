export default {
  setupComponent() {
    Ember.run.scheduleOnce('afterRender', () => {
      $('.user-card-additional-controls-outlet #follow-toggle').appendTo('ul.usercard-controls');
    });
  }
}
