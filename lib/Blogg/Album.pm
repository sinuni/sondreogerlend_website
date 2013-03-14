package Blogg::Album;
use Mojo::Base 'Mojolicious::Controller';
use Db;
use utf8;

# This action will render a template
sub index {
    my $self = shift;

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $images = Db::getImagesForEachTravel();
    $self->stash(images => $images);
    Db::disconnect();

    $self->render();
}
sub tags {
    my $self = shift;
    my $travel = $self->param('travel');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $tags = Db::getTags($travel);
    Db::disconnect();

    $self->stash(tags => $tags);
    $self->stash(travel => $travel);

    $self->render();
}

sub album {
    my $self = shift;
    
    my $tag = $self->param('tag');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $images = Db::getImagesFromTag($tag);
    $self->stash(images => $images);
    $self->stash(tag => $tag);
    Db::disconnect();

    $self->render('album/album');
}

1;
