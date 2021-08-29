export default {
  setupComponent() {
    Ember.run.scheduleOnce('afterRender', () => {
      $('.user-profile-controls-outlet .follow-cycle').appendTo('.user-main .primary .controls ul');
    });
  }
}
