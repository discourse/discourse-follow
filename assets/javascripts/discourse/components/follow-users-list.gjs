import Component from "@ember/component";
import { notEmpty } from "@ember/object/computed";
import userInfo from "discourse/components/user-info";
import { propertyEqual } from "discourse/lib/computed";
import discourseComputed from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";

export default class FollowUsersList extends Component {
  @notEmpty("users") hasUsers;
  @propertyEqual("user.username", "currentUser.username") viewingSelf;

  @discourseComputed("type", "viewingSelf")
  noneMessage(type, viewingSelf) {
    let key = viewingSelf ? "none" : "none_other";
    return `user.${type}.${key}`;
  }

  <template>
    <div class="follow-users">
      {{#if this.hasUsers}}
        {{#each this.users as |user|}}
          {{userInfo user=user}}
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
