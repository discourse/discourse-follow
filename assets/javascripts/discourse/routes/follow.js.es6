import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  afterModel(model) {
    if (!model.can_see_follow) {
      this.transitionTo("user");
    } else if (model.can_see_following) {
      this.transitionTo("following");
    } else if (model.can_see_followers) {
      this.transitionTo("followers");
    }
  },

  actions:{
    refreshFollow(){
      this.refresh();
    }
  }
});