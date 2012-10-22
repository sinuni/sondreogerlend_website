package Blogg::Admin::Editor;
use Mojo::Base ('Mojolicious::Controller');
use Db;
use utf8;

# This action will render a template
sub index {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    `rm public/images/editor_temp/*`;

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my ($travels, $selected) = Db::getTravels;
    Db::disconnect();
    $self->stash(travels => $travels);
    $self->stash(selected => $selected);

    # Render template "example/welcome.html.ep" with message
    $self->render('/admin/editor/index');
}

sub uploadHtml {
    my $self = shift;

    my $commands = Mojolicious::Commands->new;
    my $tag = $self->param('tag');
    my $travel = $self->param('travel');
    my $html = $self->param('html');
    my $name = $self->param('name');
    
    $self->app->log->debug("---tag: $tag");
    $self->app->log->debug("---travel: $travel");
    $self->app->log->debug("---html: $html");
    $self->app->log->debug("---name: $name");

    $tag = "notag" if $tag eq "";
    $travel = "notravel" if $travel eq "";

    my $replace = "$travel/$tag/posts";
    $html =~ s/editor_temp/$replace/g;
    $self->app->log->debug("---html-etter: $html");

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    Db::addPost(\$name, \$html, $tag, $travel);
    Db::setSelectedTravel($travel);
    Db::disconnect();

    $commands->create_dir("public/images/$travel/$tag/posts/") 
                unless -d "public/images/$travel/$tag/posts/";
    `cp public/images/editor_temp/* public/images/$travel/$tag/posts/`;

    $self->redirect_to('/admin/editor');
}

sub uploadImage {
    my $self = shift;
    
    my $image = $self->req->upload('userfile');
    if ($image->size == 0) {
        $self->flash(message => 'Du må velge en fil');
        $self->redirect_to('error');
    } 
    my $file = $image->{'filename'};
    $image->move_to("public/images/editor_temp/$file");

    $self->render('/admin/editor/ajax_upload_result', file_name => "/images/editor_temp/$file", result => 'virk', resultcode => 'worded');
}
1;
