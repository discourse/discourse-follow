import showModal from "discourse/lib/show-modal";

export default Ember.Component.extend({
  classNames: 'follow-admin',

  init() {
    this._super();
  },

  actions: {
    deleteNotifications() {
      showModal('follow-delete-notifications');
    }
  }
})
