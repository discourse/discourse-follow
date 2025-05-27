import Component from "@ember/component";
import { LinkTo } from "@ember/routing";
import { classNames, tagName } from "@ember-decorators/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

@tagName("li")
@classNames("user-main-nav-outlet", "follow-user-container")
export default class FollowUserContainer extends Component {
  <template>
    {{#if this.model.can_see_network_tab}}
      <LinkTo @route="follow">
        {{icon "users"}}
        <span>{{i18n "user.follow_nav"}}</span>
      </LinkTo>
    {{/if}}
  </template>
}
