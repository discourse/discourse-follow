import RouteTemplate from "ember-route-template";
import { and, eq } from "truth-helpers";
import DNavigationItem from "discourse/components/d-navigation-item";
import HorizontalOverflowNav from "discourse/components/horizontal-overflow-nav";
import bodyClass from "discourse/helpers/body-class";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    {{bodyClass "user-follow-page"}}

    <div class="user-navigation user-navigation-secondary">
      <HorizontalOverflowNav>
        {{#if (eq @controller.model.id @controller.currentUser.id)}}
          <DNavigationItem @route="feed">
            <span>{{i18n "user.feed.label"}}</span>
          </DNavigationItem>
        {{/if}}

        {{#if @controller.model.can_see_following}}
          <DNavigationItem @route="following">
            <span>{{i18n "user.following.label"}}</span>
          </DNavigationItem>
        {{/if}}

        {{#if
          (and
            @controller.model.can_see_followers
            @controller.model.allow_people_to_follow_me
          )
        }}
          <DNavigationItem @route="followers">
            <span>{{i18n "user.followers.label"}}</span>
          </DNavigationItem>
        {{/if}}
      </HorizontalOverflowNav>
    </div>

    <section class="user-content user-follows-tab">
      {{outlet}}
    </section>
  </template>
);
