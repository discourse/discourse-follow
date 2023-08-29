import I18n from "I18n";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

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
          },
        ],
        total_rows_notifications: 1,
      });
    });
  });

  test("shows follow notification", async (assert) => {
    await visit("/u/eviltrout/notifications");

    const notification = document.querySelector(".notifications .item");
    assert.strictEqual(
      notification.textContent,
      "steaky has started following you.",
      "shows the user that has followed you"
    );

    assert.ok(
      notification.querySelector("a").href.includes("/u/steaky"),
      "leads to the user's profile"
    );

    assert.strictEqual(
      notification.querySelector("a").title,
      I18n.t("notifications.titles.following"),
      "displays the right title"
    );
  });
});
