export default {
  shouldRender(_, component) {
    return component.siteSettings.follow_show_statistics_on_profile;
  },
};
