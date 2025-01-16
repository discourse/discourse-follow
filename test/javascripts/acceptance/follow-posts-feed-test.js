import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  exists,
  query,
  queryAll,
} from "discourse/tests/helpers/qunit-helpers";
import I18n from "I18n";

acceptance("Discourse Follow - Follow Posts Feed", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/posts/by_number/65/7.json", () => {
      return helper.response({
        id: 141,
        name: "Bruce Superman",
        username: "brucesuperman",
        avatar_template: "/letter_avatar_proxy/v4/letter/e/9f8e36/{size}.png",
        created_at: "2021-03-18T05:16:02.137Z",
        cooked:
          '<h3>\n<a name="et" class="anchor" href="#et"></a>Et</h3>\n<p>Corrupti nostrum odio. Autem voluptates quia. Reiciendis possimus odit. Vel ea reprehenderit. Laborum voluptas minima.<br>\n0. Quam.</p>\n<ol>\n<li>Expedita.</li>\n<li>Natus.</li>\n<li>Ea.</li>\n<li>Debitis.</li>\n<li>Ut.</li>\n<li>Suscipit.</li>\n<li>Eaque.</li>\n</ol>',
        post_number: 7,
        post_type: 1,
        updated_at: "2021-03-18T05:16:02.137Z",
        reply_count: 0,
        reply_to_post_number: null,
        quote_count: 0,
        incoming_link_count: 0,
        reads: 5,
        readers_count: 4,
        score: 1,
        yours: false,
        topic_id: 65,
        topic_slug: "what-is-your-favorite-ted-video",
        display_username: "Bruce Superman",
        primary_group_name: "partners",
        flair_name: null,
        flair_url: null,
        flair_bg_color: null,
        flair_color: null,
        version: 1,
        can_edit: true,
        can_delete: true,
        can_recover: false,
        can_wiki: true,
        user_title: null,
        bookmarked: false,
        raw: "### Et\nCorrupti nostrum odio. Autem voluptates quia. Reiciendis possimus odit. Vel ea reprehenderit. Laborum voluptas minima.\n0. Quam. \n1. Expedita. \n2. Natus. \n3. Ea. \n4. Debitis. \n5. Ut. \n6. Suscipit. \n7. Eaque.",
        actions_summary: [
          { id: 2, can_act: true },
          { id: 3, can_act: true },
          { id: 4, can_act: true },
          { id: 8, can_act: true },
          { id: 6, can_act: true },
          { id: 7, can_act: true },
        ],
        moderator: false,
        admin: false,
        staff: false,
        user_id: 34,
        hidden: false,
        trust_level: 2,
        deleted_at: null,
        user_deleted: false,
        edit_reason: null,
        can_view_edit_history: true,
        wiki: false,
        reviewable_id: null,
        reviewable_score_count: 0,
        reviewable_score_pending_count: 0,
      });
    });
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
            excerpt:
              '<a name="et" class="anchor" href="#et"></a>Et\nCorrupti nostrum odio. Autem voluptates quia. Reiciendis possimus odit. Vel ea reprehenderit. Laborum voluptas minima. \n0. Quam. \n\nExpedita.\nNatus.\nEa.\nDebitis.\nUt.\nSuscipit.\nEaque.',
            category_id: 2,
            truncated: true,
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
    const posts = queryAll(".user-follows-tab .user-stream-item");
    assert.equal(
      posts.length,
      3,
      "all posts from the server response are rendered"
    );
    assert.equal(
      query(".user-navigation-secondary  a.active").textContent.trim(),
      I18n.t("user.feed.label"),
      "feed tab is labelled correctly"
    );
  });

  test("long posts excerpt", async (assert) => {
    await visit("/u/eviltrout/follow/feed");
    const posts = queryAll(".user-follows-tab .user-stream-item");
    assert.ok(
      exists(posts[2].querySelector(".expand-item")),
      "long posts are first rendered collapsed"
    );
    await click(posts[2].querySelector(".expand-item"));
    assert.ok(
      exists(posts[2].querySelector(".collapse-item")),
      "long posts can be expanded"
    );
  });
});

acceptance("Discourse Follow - Empty Follow Posts Feed", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/follow/posts/eviltrout", () => {
      return helper.response({
        posts: [],
        __rest_serializer: "1",
        extras: { has_more: false },
      });
    });
  });

  test("with empty posts feed", async (assert) => {
    await visit("/u/eviltrout/follow/feed");
    assert.equal(
      query(".user-content.user-follows-tab").textContent.trim(),
      I18n.t("user.feed.empty_feed_you"),
      "empty posts feed notice is shown"
    );
  });
});
