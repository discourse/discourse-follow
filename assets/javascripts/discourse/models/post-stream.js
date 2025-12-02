import { tracked } from "@glimmer/tracking";
import EmberObject from "@ember/object";
import { dependentKeyCompat } from "@ember/object/compat";
import { ajax } from "discourse/lib/ajax";
import { addUniqueValuesToArray } from "discourse/lib/array-tools";
import { trackedArray } from "discourse/lib/tracked-tools";
import Category from "discourse/models/category";
import RestModel from "discourse/models/rest";

// this class implements an interface similar to the `UserStream` class in core
// (app/models/user-stream.js) so we can use it with the `{{user-stream}}`
// component (in core as well) which expects a `UserStream` instance.

export default class PostStream extends RestModel {
  @tracked canLoadMore = true;
  @tracked itemsLoaded = 0;
  @tracked loading = false;
  @trackedArray content = [];

  @dependentKeyCompat
  get lastPostCreatedAt() {
    return this.content.at(-1)?.created_at;
  }

  @dependentKeyCompat
  get noContent() {
    return !this.loading && this.content.length === 0;
  }

  async findItems() {
    if (!this.canLoadMore || this.loading) {
      return;
    }

    this.loading = true;
    const data = {};
    if (this.lastPostCreatedAt) {
      data.created_before = this.lastPostCreatedAt;
    }
    try {
      const content = await ajax(`/follow/posts/${this.user.username}`, {
        data,
      });
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
      addUniqueValuesToArray(this.content, streamItems);
      this.itemsLoaded = this.content.length;
      this.canLoadMore = content.extras.has_more;
    } finally {
      this.loading = false;
    }
  }
}
