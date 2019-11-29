export default Discourse.Route.extend({
  afterModel(model) {
    if (!model.can_see_follow)
      this.transitionTo("user");
    else if (model.can_see_following)
      this.transitionTo("following");
  },

  actions:{
    refreshFollow(){
      this.refresh();
    }
  }
});
