import Component from "@ember/component";
import { action } from "@ember/object";
import { alias } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed from "discourse/lib/decorators";

export default class FollowButton extends Component {
  loading = false;

  @alias("user.is_followed") isFollowed;
  @alias("user.can_follow") canFollow;

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
  }

  @discourseComputed("isFollowed", "canFollow")
  labelKey(isFollowed, canFollow) {
    if (isFollowed && canFollow) {
      return "follow.unfollow_button_label";
    } else {
      return "follow.follow_button_label";
    }
  }

  @discourseComputed("isFollowed", "canFollow")
  icon(isFollowed, canFollow) {
    if (isFollowed && canFollow) {
      return "user-xmark";
    } else {
      return "user-plus";
    }
  }

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
  }
}
