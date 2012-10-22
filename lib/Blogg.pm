package Blogg;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Set secure passphrase
  $self->secret('fr1h3t:)');

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('home#index');
  $r->get('/video')->to('home#video');
  $r->get('/omoss')->to('home#omoss');
  $r->get('/albums')->to('album#index');
  $r->get('/album')->to('album#album');
  $r->get('/error')->to('error#index');
  $r->get('/admin')->to('admin#index');
#  $r->post('/admin')->to('admin#index');
  $r->get('/admin/login')->to('admin#login');
  $r->post('/admin/validate')->to('admin#validate');
  $r->post('/admin/upload')->to('admin#upload');
  $r->post('/admin/uploadVideo')->to('admin#uploadVideo');
  $r->post('/admin/newTravel')->to('admin#newTravel');
  $r->get('/admin/remove')->to('admin-remove#index');
  $r->get('/admin/remove/posts')->to('admin-remove#posts');
  $r->post('/admin/remove/imagesbyname')->to('admin-remove#imagesByName');
  $r->post('/admin/remove/postsbyid')->to('admin-remove#postsById');
  $r->get('/admin/editor')->to('admin-editor#index');
  $r->post('/admin/editor/uploadImage')->to('admin-editor#uploadImage');
  $r->post('/admin/editor/uploadHtml')->to('admin-editor#uploadHtml');
}

1;
