import Controller from "@ember/controller";
import { propertyEqual } from "discourse/lib/computed";

export default Controller.extend({
  viewingSelf: propertyEqual("model.user.id", "currentUser.id"),
});
