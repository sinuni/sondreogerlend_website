package Blogg::Error;
use Mojo::Base 'Mojolicious::Controller';
use utf8;

# This action will render a template
sub index {
    my $self = shift;

    # Render template "example/welcome.html.ep" with message
    $self->render();
}

1;
