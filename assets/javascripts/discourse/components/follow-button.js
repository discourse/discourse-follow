import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { action } from "@ember/object";
import { alias } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Component.extend({
  loading: false,
  isFollowed: alias("user.is_followed"),

  @discourseComputed("user", "currentUser")
  showButton(user, currentUser) {
    if (!currentUser) {
      return false;
    }
    if (currentUser.id === user.id) {
      return false;
    }
    if (user.suspended) {
      return false;
    }
    if (user.staged) {
      return false;
    }
    if (user.id < 1) {
      // bot
      return false;
    }
    return true;
  },

  @discourseComputed("isFollowed")
  labelKey(isFollowed) {
    if (isFollowed) {
      return "follow.unfollow_button_label";
    } else {
      return "follow.follow_button_label";
    }
  },

  @discourseComputed("isFollowed")
  icon(isFollowed) {
    if (isFollowed) {
      return "user-times";
    } else {
      return "user-plus";
    }
  },

  @action
  toggleFollow() {
    const type = this.isFollowed ? "DELETE" : "PUT";
    this.set("loading", true);
    ajax(`/follow/${this.user.username}.json`, { type })
      .then(() => {
        this.set("isFollowed", !this.isFollowed);
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.set("loading", false);
      });
  },
});
