import RouteTemplate from "ember-route-template";
import followUsersList from "../components/follow-users-list";

export default RouteTemplate(
  <template>
    {{followUsersList
      users=@controller.users
      type="following"
      user=@controller.user
    }}
  </template>
);
