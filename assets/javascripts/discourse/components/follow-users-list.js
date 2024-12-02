import Component from "@ember/component";
import { notEmpty } from "@ember/object/computed";
import { propertyEqual } from "discourse/lib/computed";
import discourseComputed from "discourse-common/utils/decorators";

export default class FollowUsersList extends Component {
  @notEmpty("users") hasUsers;
  @propertyEqual("user.username", "currentUser.username") viewingSelf;

  @discourseComputed("type", "viewingSelf")
  noneMessage(type, viewingSelf) {
    let key = viewingSelf ? "none" : "none_other";
    return `user.${type}.${key}`;
  }
}
