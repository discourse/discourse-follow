import RouteTemplate from "ember-route-template";
import FollowUsersList from "../components/follow-users-list";

export default RouteTemplate(
  <template>
    <FollowUsersList
      @users={{@controller.users}}
      @type="following"
      @user={{@controller.user}}
    />
  </template>
);
