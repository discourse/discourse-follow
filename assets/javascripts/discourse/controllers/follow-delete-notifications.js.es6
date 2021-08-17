import { ajax } from 'discourse/lib/ajax';
import { default as computed, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  actions: {
    deleteNotifications() {
      ajax('/admin/follow/delete_notifications', {
        type: 'DELETE'
      }).then((result) => {
        // TODO consider some feedback
      }).finally(() => {
        this.send("closeModal");
      })
    }
  }
});
