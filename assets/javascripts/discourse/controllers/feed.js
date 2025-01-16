import Controller from "@ember/controller";
import { action } from "@ember/object";
import { propertyEqual } from "discourse/lib/computed";

export default class FeedController extends Controller {
  @propertyEqual("model.user.id", "currentUser.id") viewingSelf;

  @action
  async loadMore() {
    if (!this.model.canLoadMore) {
      return [];
    }

    await this.model.findItems();

    return this.model.content;
  }
}
