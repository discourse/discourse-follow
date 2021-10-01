import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model(/*params*/) {
    return ajax(`/u/${this.paramsFor("user").username}/follow/followers`);
  },

  setupController(controller, model) {
    controller.setProperties({
      users: model,
      user: this.modelFor("user"),
    });
  },
});
