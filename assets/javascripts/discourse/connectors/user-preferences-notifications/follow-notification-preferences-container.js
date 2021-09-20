export default {
  shouldRender(_, component) {
    return component.siteSettings.follow_notifications_enabled;
  },
};
