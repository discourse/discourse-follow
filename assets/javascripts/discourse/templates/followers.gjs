import FollowUsersList from "../components/follow-users-list";

export default <template>
  <FollowUsersList
    @users={{@controller.users}}
    @type="followers"
    @user={{@controller.user}}
  />
</template>
