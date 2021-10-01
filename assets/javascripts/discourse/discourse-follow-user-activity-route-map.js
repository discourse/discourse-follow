export default {
  resource: "user.userActivity",

  map() {
    this.route("follow", { path: "follow" });
  },
};
