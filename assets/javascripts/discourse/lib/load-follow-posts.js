import Topic from "discourse/models/topic";
import User from "discourse/models/user";
import { ajax } from "discourse/lib/ajax";
import EmberObject from "@ember/object";

export function loadFollowPosts(username, { createdBefore } = {}) {
  const data = {};
  if (createdBefore) {
    data.created_before = createdBefore;
  }
  return ajax(`/follow/posts/${username}`, { data }).then((content) => {
    const posts = content.posts.map((post) => {
      post.user = User.create(post.user);
      post.topic.category_id = post.category_id;
      delete post.category_id;
      post.topic = Topic.create(post.topic);
      return EmberObject.create(post);
    });
    return { posts, hasMore: content.extras.has_more };
  });
}
