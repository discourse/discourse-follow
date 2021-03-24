export default {
  shouldRender(_, ctx) {
    return (
      ctx.siteSettings.discourse_follow_enabled &&
      ctx.siteSettings.follow_notifications_enabled
    );
  },
};
