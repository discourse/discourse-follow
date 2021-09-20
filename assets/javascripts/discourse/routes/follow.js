import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  afterModel(model) {
    if (!model.can_see_network_tab) {
      this.transitionTo("user");
    } else if (!model.can_see_following) {
      this.transitionTo("followers");
    } else if (!model.can_see_followers) {
      this.transitionTo("following");
    }
  },
});
