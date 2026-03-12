/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { computed } from "@ember/object";
import { notEmpty } from "@ember/object/computed";
import UserInfo from "discourse/components/user-info";
import { propertyEqual } from "discourse/lib/computed";
import { i18n } from "discourse-i18n";

export default class FollowUsersList extends Component {
  @notEmpty("users") hasUsers;
  @propertyEqual("user.username", "currentUser.username") viewingSelf;

  @computed("type", "viewingSelf")
  get noneMessage() {
    let key = this.viewingSelf ? "none" : "none_other";
    return `user.${this.type}.${key}`;
  }

  <template>
    <div class="follow-users">
      {{#if this.hasUsers}}
        {{#each this.users as |user|}}
          <UserInfo @user={{user}} />
        {{/each}}
      {{else}}
        <div class="alert alert-info">{{i18n
            this.noneMessage
            username=this.user.username
          }}</div>
      {{/if}}
    </div>
  </template>
}
