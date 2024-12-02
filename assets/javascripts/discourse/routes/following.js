import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class Following extends DiscourseRoute {
  model() {
    return ajax(`/u/${this.paramsFor("user").username}/follow/following`);
  }

  setupController(controller, model) {
    const user = this.modelFor("user");
    controller.setProperties({ users: model, user });
  }
}
