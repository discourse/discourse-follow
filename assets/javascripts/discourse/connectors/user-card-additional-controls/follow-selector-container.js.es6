export default {
  setupComponent(attrs, component) {
    
    Ember.run.scheduleOnce('afterRender', () => {
      const $container = $(component.get('element'));
      const $usercardControls = $container.siblings('ul.usercard-controls');
      const container = 'li.follow-selector-container';
      
      if (!$usercardControls.find(container).length) {
        $usercardControls.append($container.find(container));
      }
    });
 }
}
