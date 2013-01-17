package Blogg;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Set secure passphrase
  $self->secret('fr1h3t:)');

  # Set max upload size to 1GB 
  $ENV{MOJO_MAX_MESSAGE_SIZE} = 1073741824;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('home#index');
  $r->get('/video')->to('home#video');
  $r->get('/omoss')->to('home#omoss');
  $r->get('/kart')->to('home#kart');
  $r->post('/getimgdescription')->to('home#getImgDescription');
  $r->get('/albums')->to('album#index');
  $r->get('/album')->to('album#album');
  $r->get('/error')->to('error#index');
  $r->post('/comment/post')->to('comment#post');
  $r->get('/admin')->to('admin#index');
#  $r->post('/admin')->to('admin#index');
  $r->get('/admin/login')->to('admin#login');
  $r->post('/admin/validate')->to('admin#validate');
  $r->post('/admin/upload')->to('admin#upload');
  $r->post('/admin/uploadVideo')->to('admin#uploadVideo');
  $r->post('/admin/newTravel')->to('admin#newTravel');
  $r->get('/admin/remove')->to('admin-remove#index');
  $r->get('/admin/remove/posts')->to('admin-remove#posts');
  $r->get('/admin/remove/videos')->to('admin-remove#videos');
  $r->post('/admin/remove/imagesbyname')->to('admin-remove#imagesByName');
  $r->post('/admin/remove/postsbyid')->to('admin-remove#postsById');
  $r->post('/admin/remove/videosbyvideoid')->to('admin-remove#videosByVideoId');
  $r->get('/admin/editor')->to('admin-editor#index');
  $r->post('/admin/editor/uploadImage')->to('admin-editor#uploadImage');
  $r->post('/admin/editor/uploadHtml')->to('admin-editor#uploadHtml');
  $r->get('/admin/imgbrowser')->to('admin-imgbrowser#index');
  $r->post('/admin/imgbrowser/changedir')->to('admin-imgbrowser#changeDir');
  $r->post('/admin/imgbrowser/updatedescription')->to('admin-imgbrowser#updateDescription');
}

1;
