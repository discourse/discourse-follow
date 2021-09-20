import Controller from "@ember/controller";
import discourseComputed from "discourse-common/utils/decorators";
import { notEmpty } from "@ember/object/computed";

export default Controller.extend({
  hasUsers: notEmpty("users"),

  @discourseComputed("viewing")
  viewingSelf(viewing) {
    return viewing === this.get("currentUser.username");
  },

  @discourseComputed("type", "viewingSelf")
  noneMessage(type, viewingSelf) {
    let key = viewingSelf ? "none" : "none_other";
    return `user.${type}.${key}`;
  },
});
