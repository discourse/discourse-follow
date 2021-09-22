import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  beforeModel() {
    const model = this.modelFor("user");
    const canSeeFollowers = model.can_see_followers;
    const canSeeFollowing = model.can_see_following;

    if (canSeeFollowing) {
      this.replaceWith("following");
    } else if (canSeeFollowers) {
      this.replaceWith("followers");
    } else {
      this.replaceWith("user");
    }
  },
});
