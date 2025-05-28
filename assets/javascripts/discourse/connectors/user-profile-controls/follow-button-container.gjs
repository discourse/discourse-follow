import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import FollowButton from "../../components/follow-button";

@tagName("li")
@classNames("user-profile-controls-outlet", "follow-button-container")
export default class FollowButtonContainer extends Component {
  <template><FollowButton @user={{this.model}} /></template>
}
