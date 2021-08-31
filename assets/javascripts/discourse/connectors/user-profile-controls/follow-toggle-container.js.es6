export default {
  setupComponent() {
    Ember.run.scheduleOnce('afterRender', () => {
      $('.user-profile-controls-outlet .follow-selector-container').appendTo('.user-main .primary .controls ul');
    });
  }
}
