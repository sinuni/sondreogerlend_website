package Blogg::Reiser;
use Mojo::Base 'Mojolicious::Controller';
use Db;
use utf8;

sub index {
    my $self = shift;

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $travels =  Db::getInfoForEachTravel();
    $self->stash(travels => $travels);
    Db::disconnect();


    $self->render();
}

sub reise {
    my $self = shift;
    my $travel = $self->param('travel');
    my $page = $self->param('page');
    $page = 1 if $page == undef;

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $data = Db::getImagesAndPostsByPageAndTravel($page, $travel);
    Db::disconnect();
    $self->stash(elements => $data->{'elements'});
    $self->stash(pages => $data->{'pages'});
    $self->stash(travel => $travel);
    $self->stash(page => $page);

    $self->render();
}

sub rss {
    my $self = shift;

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $posts = Db::getPostsWithPagenr();
    Db::disconnect();

    $self->stash(posts => $posts);
    $self->render(format => 'rss');
}

1;
