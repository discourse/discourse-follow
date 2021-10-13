import DiscourseRoute from "discourse/routes/discourse";
import PostStream from "../models/post-stream";

export default DiscourseRoute.extend({
  model() {
    return PostStream.create({ user: this.modelFor("user") });
  },

  afterModel(model) {
    return model.findItems();
  },
});
