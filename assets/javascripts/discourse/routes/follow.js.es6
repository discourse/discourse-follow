export default Discourse.Route.extend({
  beforeModel() {
    this.replaceWith('following');
  },

  actions:{
    refreshFollow(){
      this.refresh();
    }
  }
});
