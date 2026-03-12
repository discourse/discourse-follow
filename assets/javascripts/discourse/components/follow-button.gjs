/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { action, computed } from "@ember/object";
import { alias } from "@ember/object/computed";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { and } from "discourse/truth-helpers";

export default class FollowButton extends Component {
  loading = false;

  @alias("user.is_followed") isFollowed;
  @alias("user.can_follow") canFollow;

  @computed("user", "currentUser")
  get showButton() {
    if (!this.currentUser) {
      return false;
    }
    if (this.currentUser.id === this.user.id) {
      return false;
    }
    if (this.user.suspended) {
      return false;
    }
    if (this.user.staged) {
      return false;
    }
    if (this.user.id < 1) {
      // bot
      return false;
    }
    return true;
  }

  @computed("isFollowed", "canFollow")
  get labelKey() {
    if (this.isFollowed && this.canFollow) {
      return "follow.unfollow_button_label";
    } else {
      return "follow.follow_button_label";
    }
  }

  @computed("isFollowed", "canFollow")
  get icon() {
    if (this.isFollowed && this.canFollow) {
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

  <template>
    {{#if (and this.showButton this.canFollow)}}
      <DButton
        @label={{this.labelKey}}
        @icon={{this.icon}}
        @disabled={{this.loading}}
        @action={{this.toggleFollow}}
        class="btn-default"
      />
    {{/if}}
  </template>
}
