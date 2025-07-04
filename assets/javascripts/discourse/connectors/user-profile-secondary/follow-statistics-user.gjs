import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import FollowStatistic from "../../components/follow-statistic";

@tagName("")
@classNames("user-profile-secondary-outlet", "follow-statistics-user")
export default class FollowStatisticsUser extends Component {
  static shouldRender(_, context) {
    return context.siteSettings.follow_show_statistics_on_profile;
  }

  <template>
    {{#if this.model.total_following}}
      <FollowStatistic
        @label="user.following.label"
        @total={{this.model.total_following}}
      />
    {{/if}}

    {{#if this.model.total_followers}}
      <FollowStatistic
        @label="user.followers.label"
        @total={{this.model.total_followers}}
      />
    {{/if}}
  </template>
}
