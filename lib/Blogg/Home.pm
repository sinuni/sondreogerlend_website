package Blogg::Home;
use Mojo::Base 'Mojolicious::Controller';
use Db;
use utf8;

# This action will render a template
sub index {
    my $self = shift;

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $images = Db::getImages();
    $self->stash(images => $images);

    my $elements = Db::getImagesAndPosts();
    $self->stash(elements => $elements);
    Db::disconnect();

    # Render template "example/welcome.html.ep" with message
    my $message = "Velkommen på norsk:) $images->{'2012-08-10'}->[1]->{'name'}";
    $self->render( message => $message);
}

sub video {
    my $self = shift;

    my $videofile = $self->param('videofile');
    $self->render(videofile => $videofile);
}

sub omoss {
    my $self = shift;

    $self->render();
}

1;
