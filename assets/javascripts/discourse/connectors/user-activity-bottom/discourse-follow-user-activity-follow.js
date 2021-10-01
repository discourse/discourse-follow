export default {
  shouldRender(args, component) {
    const currentUser = component.currentUser;
    return currentUser?.id === args.model.id || currentUser?.staff;
  },
};
