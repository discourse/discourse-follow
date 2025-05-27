import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import followButton from "../../components/follow-button";

@tagName("li")
@classNames("user-card-additional-buttons-outlet", "follow-button-container")
export default class FollowButtonContainer extends Component {
  <template>{{followButton user=this.user}}</template>
}
