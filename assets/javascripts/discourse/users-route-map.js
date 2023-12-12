export default {
  resource: "user",
  map() {
    this.route("follow", { resetNamespace: true }, function () {
      this.route("feed", { resetNamespace: true });
      this.route("followers", { resetNamespace: true });
      this.route("following", { resetNamespace: true });
    });
  },
};
