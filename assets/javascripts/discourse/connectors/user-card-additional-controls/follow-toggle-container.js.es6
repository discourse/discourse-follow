export default {
  setupComponent(attrs, component) {
    
    Ember.run.scheduleOnce('afterRender', () => {
      const $container = $(component.get('element'));
      const $usercardControls = $container.siblings('ul.usercard-controls');
      const cycle = 'li.follow-cycle';
      
      if (!$usercardControls.find(cycle).length) {
        $usercardControls.append($container.find(cycle));
      }
    });
  }
}
