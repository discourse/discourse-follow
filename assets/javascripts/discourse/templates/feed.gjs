import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import RouteTemplate from "ember-route-template";
import PostList from "discourse/components/post-list";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  class extends Component {
    @service currentUser;

    get viewingSelf() {
      return this.args.model.user.id === this.currentUser.id;
    }

    @action
    async loadMore() {
      if (!this.args.model.canLoadMore) {
        return [];
      }

      await this.args.model.findItems();

      return this.args.model.content;
    }

    <template>
      {{#if @model.noContent}}
        {{#if this.viewingSelf}}
          <div class="alert alert-info">{{i18n
              "user.feed.empty_feed_you"
            }}</div>
        {{else}}
          <div class="alert alert-info">
            {{i18n "user.feed.empty_feed_other" username=@model.user.username}}
          </div>
        {{/if}}
      {{else}}
        <PostList
          @urlPath="postUrl"
          @posts={{@model.content}}
          @fetchMorePosts={{this.loadMore}}
          @additionalItemClasses="follow-stream-item"
          class="follow-stream"
        />
      {{/if}}
    </template>
  }
);
