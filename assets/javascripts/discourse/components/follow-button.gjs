/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { action, computed } from "@ember/object";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class FollowButton extends Component {
  loading = false;

  @computed("user.is_followed", "user.can_follow")
  get showButton() {
    return this.user.is_followed || this.user.can_follow;
  }

  @computed("user.is_followed")
  get labelKey() {
    if (this.user.is_followed) {
      return "follow.unfollow_button_label";
    } else {
      return "follow.follow_button_label";
    }
  }

  @computed("user.is_followed")
  get icon() {
    if (this.user.is_followed) {
      return "user-xmark";
    } else {
      return "user-plus";
    }
  }

  @action
  toggleFollow() {
    const type = this.user.is_followed ? "DELETE" : "PUT";
    this.set("loading", true);
    ajax(`/follow/${this.user.username}.json`, { type })
      .then(() => {
        this.set("user.is_followed", !this.user.is_followed);
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.set("loading", false);
      });
  }

  <template>
    {{#if this.showButton}}
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
