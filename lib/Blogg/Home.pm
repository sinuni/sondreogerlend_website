package Blogg::Home;
use 5.010;
use Mojo::Base 'Mojolicious::Controller';
use Db;
use utf8;
use utf8::all;

my $month = {'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4, 'may' => 5, 'jun' => 6, 'jul' => 7, 'aug' => 8, 'sep' => 9, 'okt' => 10, 'nov' => 11, 'des' => 12};

#sub index {
#   my $self = shift;

#   Db::connect('blogg', 'tiro', 'kokid8Ei');
#   my $images = Db::getImages();
#   $self->stash(images => $images);

#   my $elements;
#   if (defined $self->param('month')) {
#       my $y = $self->param('year');
#       my $m = $self->param('month');
#       $elements = Db::getImagesAndPostsByMonth($y, $month->{$m});
#   } else {
#       $elements = Db::getImagesAndPosts();
#   }
#   $self->stash(elements => $elements);
#   Db::disconnect();

#   $self->render();
#}

sub index {
    my $self = shift;
    my $travel = $self->param('travel');
    my $page = $self->param('page');
    $page = 1 if $page == undef;

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    $travel = Db::getActiveTravel() if $travel == undef;
    my $data = Db::getImagesAndPostsByPageAndTravel($page, $travel);
    Db::disconnect();
    $self->stash(elements => $data->{'elements'});
    $self->stash(pages => $data->{'pages'});
    $self->stash(travel => $travel);
    $self->stash(page => $page);

    $self->render();
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

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $travel = Db::getActiveTravel();
    my $mapData = Db::getMapData($travel);
    Db::disconnect();

    $self->stash(travel => $travel);
    $self->stash(mapData => $mapData);

    $self->render();
}

sub getPost {
    my $self = shift;
    my $postid = $self->param('postid');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $post = Db::getPostById($postid);
    Db::disconnect();

    $self->render(json => $post );
}

sub getImgDescription {
    my $self = shift;
    my $imageid = $self->param('imageid');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $description = Db::getImageDescription($imageid);
    Db::disconnect();

    $self->render(json => { 'description' => $description });
}

sub getImgComments {
    my $self = shift;
    my $imageid = $self->param('imageid');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $comments = Db::getImageComments($imageid);
    Db::disconnect();

    $self->render(json => $comments);
}

sub addImgComment {
    my $self = shift;
    my $imageid = $self->param('imageid');
    my $name = $self->param('name');
    my $comment = $self->param('comment');
    my $response;

    if( length $comment > 300 ) {
        $response = {tolong => 1, message => "Det var en for lang kommentar. Max 300 tegn:-D"};
    } else {
#       $self->app->log->debug("imgname: $imgname, travel: $travel, name: $name, comment: $comment\n");
        Db::connect('blogg', 'tiro', 'kokid8Ei');
        $response = Db::addCommentToImage($imageid, $name, $comment);
        Db::disconnect();
    }

    $self->render(json => $response);
}

1;
