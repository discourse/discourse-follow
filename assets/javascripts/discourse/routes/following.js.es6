import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  model(params) {
    return ajax(`/u/${this.paramsFor('user').username}/follow/following`, {
      type: 'GET',
      data: {
        type: 'following'
      }
    });
  },

  setupController(controller, model) {
    this.controllerFor('follow-users').setProperties({
      users: model,
      type: 'following'
    });
  },

  renderTemplate() {
    this.render('follow-users');
  }
});
