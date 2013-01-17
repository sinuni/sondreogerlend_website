package Blogg::Home;
use 5.010;
use Mojo::Base 'Mojolicious::Controller';
use Db;
use utf8;
use utf8::all;

my $month = {'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4, 'may' => 5, 'jun' => 6, 'jul' => 7, 'aug' => 8, 'sep' => 9, 'okt' => 10, 'nov' => 11, 'des' => 12};

sub index {
    my $self = shift;

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $images = Db::getImages();
    $self->stash(images => $images);

    my $elements;
    if (defined $self->param('month')) {
        my $y = $self->param('year');
        my $m = $self->param('month');
#       $self->app->log->debug("---$m");
        $elements = Db::getImagesAndPostsByMonth($y, $month->{$m});
    } else {
        $elements = Db::getImagesAndPosts();
    }
    $self->stash(elements => $elements);
    Db::disconnect();

    # Render template "example/welcome.html.ep" with message
    $self->render();
}

sub getImgDescription {
    my $self = shift;
    my $imgname = $self->param('imgname');
    my $travel = $self->param('travel');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $description = Db::getImageDescription($travel, $imgname);
    Db::disconnect();

    $self->render(json => { 'description' => $description });
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

sub kart {
    my $self = shift;

    $self->render();
}

1;
