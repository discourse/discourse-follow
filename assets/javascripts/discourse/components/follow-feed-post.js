import Component from "@glimmer/component";
import getURL from "discourse-common/lib/get-url";

export default class DiscourseReactionsReactionPost extends Component {
  get postUrl() {
    return getURL(this.args.post.url);
  }
}
