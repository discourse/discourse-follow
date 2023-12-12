import Component from "@ember/component";
import { notEmpty } from "@ember/object/computed";
import { propertyEqual } from "discourse/lib/computed";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  hasUsers: notEmpty("users"),
  viewingSelf: propertyEqual("user.username", "currentUser.username"),

  @discourseComputed("type", "viewingSelf")
  noneMessage(type, viewingSelf) {
    let key = viewingSelf ? "none" : "none_other";
    return `user.${type}.${key}`;
  },
});
