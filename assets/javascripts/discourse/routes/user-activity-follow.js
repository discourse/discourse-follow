import DiscourseRoute from "discourse/routes/discourse";
import { loadFollowPosts } from "../lib/load-follow-posts";

export default DiscourseRoute.extend({
  model() {
    const username = this.modelFor("user").username;
    return loadFollowPosts(username);
  },

  setupController(controller, model) {
    this._super(...arguments);
    controller.set("user", this.modelFor("user"));
    controller.set("canLoadMore", model.hasMore);
  },

  renderTemplate() {
    this.render("user-activity-follow");
  },
});
