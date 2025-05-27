import RouteTemplate from "ember-route-template";
import followUsersList from "../components/follow-users-list";

export default RouteTemplate(
  <template>
    {{followUsersList
      users=@controller.users
      type="followers"
      user=@controller.user
    }}
  </template>
);
