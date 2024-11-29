import Controller from "@ember/controller";
import { propertyEqual } from "discourse/lib/computed";

export default class FeedController extends Controller {
  @propertyEqual("model.user.id", "currentUser.id") viewingSelf;
}
