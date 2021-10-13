import discourseComputed, { on } from "discourse-common/utils/decorators";
import RestModel from "discourse/models/rest";
import { reads } from "@ember/object/computed";
import { Promise } from "rsvp";
import Topic from "discourse/models/topic";
import User from "discourse/models/user";
import { ajax } from "discourse/lib/ajax";
import EmberObject from "@ember/object";

// this class implements an interface similar to the `UserStream` class in core
// (app/models/user-stream.js) so we can use it with the `{{user-stream}}`
// component (in core as well) which expects a `UserStream` instance.

export default RestModel.extend({
  loading: false,
  itemsLoaded: 0,
  canLoadMore: true,

  lastPostCreatedAt: reads("content.lastObject.created_at"),

  @on("init")
  _initialize() {
    this.set("content", []);
  },

  @discourseComputed("loading", "content.length")
  noContent(loading, length) {
    return !loading && length === 0;
  },

  findItems() {
    if (!this.canLoadMore || this.loading) {
      return Promise.resolve();
    }

    this.set("loading", true);
    const data = {};
    if (this.lastPostCreatedAt) {
      data.created_before = this.lastPostCreatedAt;
    }
    return ajax(`/follow/posts/${this.user.username}`, { data })
      .then((content) => {
        const posts = content.posts.map((post) => {
          post.user = User.create(post.user);
          post.topic.category_id = post.category_id;
          delete post.category_id;
          post.topic = Topic.create(post.topic);
          return EmberObject.create(post);
        });
        return { posts, hasMore: content.extras.has_more };
      })
      .then(({ posts, hasMore }) => {
        this.content.addObjects(posts);
        this.set("itemsLoaded", this.content.length);
        this.set("canLoadMore", hasMore);
      })
      .finally(() => {
        this.set("loading", false);
      });
  },
});
