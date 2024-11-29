import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class Followers extends DiscourseRoute {
  model /*params*/() {
    return ajax(`/u/${this.paramsFor("user").username}/follow/followers`);
  }

  setupController(controller, model) {
    controller.setProperties({
      users: model,
      user: this.modelFor("user"),
    });
  }
}
