export default {
  setupComponent() {
    Ember.run.scheduleOnce("afterRender", () => {
      $(".user-profile-controls-outlet .follow-toggle").appendTo(
        ".user-main .primary .controls ul"
      );
    });
  },
};
