import discourseComputed, { on } from "discourse-common/utils/decorators";
import RestModel from "discourse/models/rest";
import { reads } from "@ember/object/computed";
import { Promise } from "rsvp";
import Category from "discourse/models/category";
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
        const streamItems = content.posts.map((post) => {
          return EmberObject.create({
            title: post.topic.title,
            postUrl: post.url,
            created_at: post.created_at,
            category: Category.findById(post.category_id),
            topic_id: post.topic.id,
            post_id: post.id,
            post_number: post.post_number,

            username: post.user.username,
            name: post.user.name,
            avatar_template: post.user.avatar_template,
            user_id: post.user.id,

            excerpt: post.excerpt,
            truncated: post.truncated,
          });
        });
        return { posts: streamItems, hasMore: content.extras.has_more };
      })
      .then(({ posts: streamItems, hasMore }) => {
        this.content.addObjects(streamItems);
        this.set("itemsLoaded", this.content.length);
        this.set("canLoadMore", hasMore);
      })
      .finally(() => {
        this.set("loading", false);
      });
  },
});
