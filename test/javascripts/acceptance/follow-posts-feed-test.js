import {
  acceptance,
  query,
  queryAll,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import I18n from "I18n";

acceptance("Discourse Follow - Follow Posts Feed", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/follow/posts/eviltrout", () => {
      return helper.response({
        posts: [
          {
            excerpt: "test post 44432 232",
            category_id: 4,
            created_at: "2021-09-30T07:17:39.899Z",
            id: 1294,
            post_number: 2,
            post_type: 1,
            topic_id: 8,
            url: "/t/welcome-to-the-lounge/8/2",
            user: {
              id: 33,
              username: "clarkbatman",
              name: " ",
              avatar_template:
                "/letter_avatar_proxy/v4/letter/j/9f8e36/{size}.png",
            },
            topic: {
              id: 8,
              title: "Welcome to the Lounge",
              fancy_title: "Welcome to the Lounge",
              slug: "welcome-to-the-lounge",
              posts_count: 2,
            },
          },
          {
            excerpt: "hello world!",
            category_id: 22,
            created_at: "2021-09-30T07:17:19.310Z",
            id: 1293,
            post_number: 5,
            post_type: 1,
            topic_id: 49,
            url: "/t/why-is-uninhabited-land-in-the-us-so-closed-off/49/5",
            user: {
              id: 33,
              username: "clarkbatman",
              name: " ",
              avatar_template:
                "/letter_avatar_proxy/v4/letter/j/9f8e36/{size}.png",
            },
            topic: {
              id: 49,
              title: "Why is uninhabited land in the US so closed off?",
              fancy_title: "Why is uninhabited land in the US so closed off?",
              slug: "why-is-uninhabited-land-in-the-us-so-closed-off",
              posts_count: 5,
            },
          },
          {
            excerpt: "post 3523 czcs 2224",
            category_id: 2,
            created_at: "2021-09-30T07:17:00.170Z",
            id: 1292,
            post_number: 7,
            post_type: 1,
            topic_id: 65,
            url: "/t/the-room-appreciation-topic/65/7",
            user: {
              id: 34,
              username: "brucesuperman",
              name: " ",
              avatar_template:
                "/letter_avatar_proxy/v4/letter/j/9f8e36/{size}.png",
            },
            topic: {
              id: 65,
              title: "The Room Appreciation Topic",
              fancy_title: "The Room Appreciation Topic",
              slug: "the-room-appreciation-topic",
              posts_count: 7,
            },
          },
        ],
        __rest_serializer: "1",
        extras: { has_more: true },
      });
    });
  });

  test("posts are shown", async (assert) => {
    await visit("/u/eviltrout/follow/feed");
    assert.equal(
      queryAll(".user-stream .user-stream-item").length,
      3,
      "all posts from the server response are rendered"
    );
    assert.equal(
      query(".user-secondary-navigation .activity-nav a.active").textContent,
      I18n.t("user.feed.label"),
      "feed tab is labelled correctly"
    );
  });
});
