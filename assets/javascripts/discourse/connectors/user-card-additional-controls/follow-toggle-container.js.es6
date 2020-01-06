export default {
  setupComponent(attrs, component) {
    
    Ember.run.scheduleOnce('afterRender', () => {
      const $container = $(component.get('element'));
      console.log($container, $container.siblings('ul.usercard-controls'))
      const $usercardControls = $container.siblings('ul.usercard-controls');
      const toggle = 'li.follow-toggle';
      
      if (!$usercardControls.find(toggle).length) {
        $usercardControls.append($container.find(toggle));
      }
    });
  }
}
