package Blogg::Comment;
use Mojo::Base 'Mojolicious::Controller';
use Db;
use utf8;

sub index {
    my $self = shift;
}

sub post {
    my $self = shift;
    my $redirect = "/";

    my $postid = $self->param('postid');
    my $name = $self->param('name');
    my $comment = $self->param('comment');

    $self->app->log->debug("---$name");
    $self->app->log->debug("---$comment");

    if( $comment eq "" or length($comment) > 10000 ) {
        $self->flash(message => 'Commet is empty or to long');
        $redirect = "/error";
    } elsif( $name eq "" or length($name) > 50 ) {
        $self->flash(message => 'Name is empty or to long');
        $redirect = "/error";
    } else {
        Db::connect('blogg', 'tiro', 'kokid8Ei');
        Db::addCommentToPost($postid, \$name, \$comment);
        Db::disconnect();
    }

    $self->redirect_to($redirect);
}

1;
