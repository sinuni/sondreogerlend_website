package Blogg::Admin::Remove;
use Mojo::Base ('Mojolicious::Controller');
use Db;

# This action will render a template
sub index {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    Db::connect('blogg', 'tiro', 'kokid8Ei');

    my $images = Db::getImages();
    $self->stash(images => $images);
    Db::disconnect();

    # Render template "example/welcome.html.ep" with message
    $self->render('/admin/remove/images');
}

sub videos {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    Db::connect('blogg', 'tiro', 'kokid8Ei');

    my $videos = Db::getVideos();
    $self->stash(videos => $videos);
    Db::disconnect();

    # Render template "example/welcome.html.ep" with message
    $self->render('/admin/remove/videos');
}

sub posts {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    Db::connect('blogg', 'tiro', 'kokid8Ei');

    my $posts = Db::getPosts();
    $self->stash(posts => $posts);
    Db::disconnect();

    # Render template "example/welcome.html.ep" with message
    $self->render('/admin/remove/posts');
}

sub imagesByName {
    my $self = shift;

    my @images = $self->param('images[]');
#   my @images2 = @images;
    $self->app->log->debug('---Check 1');
    
    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $imgTagPairs = Db::getNamesTagsAndTravels(\@images);
    foreach my $pair ( @$imgTagPairs ) {
       `rm public/images/$pair->{'travel'}/$pair->{'tag'}/$pair->{'name'}`; 
       `rm public/images/$pair->{'travel'}/$pair->{'tag'}/thumbs/thumb_$pair->{'name'}`; 
        $self->app->log->debug('---Check 2');

       my @remindings = `ls -A public/images/$pair->{'travel'}/$pair->{'tag'}/thumbs`;
       if (@remindings == 0) {
            `rm -rf public/images/$pair->{'travel'}/$pair->{'tag'}`;     
       }
    }

    Db::rmImagesByName(\@images);
    Db::disconnect();

    $self->app->log->debug("---$_") for @images;

    $self->redirect_to('/admin/remove');
}

sub videosByVideoId {
    my $self = shift;

    my @videoIds = $self->param('videos[]');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    Db::rmVideosByVideoIds(\@videoIds);
    Db::disconnect();

    $self->redirect_to('/admin/remove');
}

sub postsById {
    my $self = shift;

    my @postIds = $self->param('posts[]');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $htmls = Db::getHtmlFromPostId(\@postIds);
    my @img2rm;

    # remove images in posts
    foreach my $html (values %$htmls) {
        while($html =~ /img src="(.+)" alt/g) {
            my $path = $1;
            $path =~ s/ /\\ /g;
            $path =~ s/^\//public\//;
            push @img2rm, $path;
        }
    }
    $self->app->log->debug("---: $_") for (@img2rm);
    `rm $_` foreach (@img2rm);

    Db::rmPostsByIds(\@postIds);
    Db::disconnect();
    $self->redirect_to('/admin/remove');
}

1;
