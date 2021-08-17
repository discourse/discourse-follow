export default {
  resource: 'admin',
  map() {
    this.route('adminFollow', { path: '/follow', resetNamespace: true }, function() {
    });
  }
};
