import Controller from "@ember/controller";
import { action } from "@ember/object";
import { loadFollowPosts } from "../lib/load-follow-posts";
import { propertyEqual } from "discourse/lib/computed";

export default Controller.extend({
  canLoadMore: true,
  loading: false,
  viewingSelf: propertyEqual("user.id", "currentUser.id"),

  @action
  loadMore() {
    if (this.loading || !this.canLoadMore) {
      return;
    }
    this.set("loading", true);
    const lastPostCreationDate = this.model.posts.lastObject.created_at;
    loadFollowPosts(this.user.username, { createdBefore: lastPostCreationDate })
      .then(({ posts, hasMore }) => {
        this.model.posts.addObjects(posts);
        this.set("canLoadMore", hasMore);
      })
      .finally(() => {
        this.set("loading", false);
      });
  },
});
