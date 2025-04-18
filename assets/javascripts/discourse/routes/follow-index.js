import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";

export default class FollowIndexRoute extends DiscourseRoute {
  @service router;

  beforeModel() {
    const model = this.modelFor("user");
    const canSeeFollowers = model.can_see_followers;
    const canSeeFollowing = model.can_see_following;

    if (this.currentUser?.id === model.id) {
      this.router.replaceWith("feed");
    } else if (canSeeFollowing) {
      this.router.replaceWith("following");
    } else if (canSeeFollowers) {
      this.router.replaceWith("followers");
    } else {
      this.router.replaceWith("user");
    }
  }
}
