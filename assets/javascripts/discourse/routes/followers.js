import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model(/*params*/) {
    return ajax(`/u/${this.paramsFor("user").username}/follow/followers`);
  },

  setupController(controller, model) {
    this.controllerFor("follow-users").setProperties({
      users: model,
      type: "followers",
      viewing: this.paramsFor("user").username,
    });
  },

  renderTemplate() {
    this.render("follow-users");
  },
});
