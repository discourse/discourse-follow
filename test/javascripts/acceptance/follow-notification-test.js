import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("Discourse Follow - notification", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/notifications", () => {
      return helper.response({
        notifications: [
          {
            id: 25201,
            user_id: 1,
            external_id: "1",
            notification_type: 800,
            read: false,
            high_priority: false,
            slug: null,
            data: {
              display_username: "steaky",
            },
            created_at: "2023-12-06 21:39:57.412408",
          },
        ],
        total_rows_notifications: 1,
      });
    });
  });

  test("shows follow notification", async (assert) => {
    await visit("/u/eviltrout/notifications");

    const notification = document.querySelector(
      ".user-notifications-list .notification"
    );

    assert.strictEqual(
      notification.querySelector(".item-label").textContent.trim(),
      "steaky",
      "Renders username"
    );

    assert.strictEqual(
      notification.querySelector(".item-description").textContent.trim(),
      "has started following you.",
      "Renders description"
    );

    assert.ok(
      notification.querySelector("a").href.includes("/u/steaky"),
      "leads to the user's profile"
    );

    assert.strictEqual(
      notification.querySelector("a").title,
      i18n("notifications.titles.following"),
      "displays the right title"
    );
  });
});
