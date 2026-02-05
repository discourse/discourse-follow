import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import { i18n } from "discourse-i18n";

@tagName("div")
@classNames("user-card-metadata-outlet", "follow-statistics-user-card")
export default class FollowStatisticsUserCard extends Component {
  static shouldRender(_, context) {
    return context.siteSettings.follow_show_statistics_on_profile;
  }

  <template>
    {{#if this.user.total_following}}
      <div class="metadata__following">
        <span class="desc">{{i18n "user.following.label"}}</span>
        <span class="value">{{this.user.total_following}}</span>
      </div>
    {{/if}}
    {{#if this.user.total_followers}}
      <div class="metadata__followers">
        <span class="desc">{{i18n "user.followers.label"}}</span>
        <span class="value">{{this.user.total_followers}}</span>
      </div>
    {{/if}}
  </template>
}
