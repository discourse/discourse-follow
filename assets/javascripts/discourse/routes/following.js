import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model(/* params */) {
    return ajax(`/u/${this.paramsFor("user").username}/follow/following`);
  },

  setupController(controller, model) {
    const user = this.modelFor("user");
    controller.setProperties({ users: model, user });
  },
});
