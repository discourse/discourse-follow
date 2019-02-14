import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  model(params) {
    return ajax(`/u/${this.paramsFor('user').username}/follow/following`, {
      type: 'GET',
      data: {
        type: 'followers'
      }
    });
  },

  setupController(controller, model) {
    this.controllerFor('follow-users').setProperties({
      users: model,
      type: 'followers'
    });
  },

  renderTemplate() {
    this.render('follow-users');
  }
});
