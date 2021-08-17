
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  actions: {
    showSettings() {
      const controller = this.controllerFor('adminSiteSettings');
      this.transitionTo('adminSiteSettingsCategory', 'plugins').then(() => {
        controller.set('filter', 'follow');
        controller.set('_skipBounce', true);
        controller.filterContentNow('plugins');
      });
    }
  }
});
