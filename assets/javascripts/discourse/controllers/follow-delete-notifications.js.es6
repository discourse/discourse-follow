import { ajax } from 'discourse/lib/ajax';
import { default as computed, observes } from 'discourse-common/utils/decorators';

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
