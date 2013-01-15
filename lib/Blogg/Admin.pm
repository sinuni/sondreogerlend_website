package Blogg::Admin;
use Mojo::Base ('Mojolicious::Controller');
use Mojolicious::Commands;
use Mojo::Upload;
use Mojo::Server::CGI;
use Db;
use utf8;

sub index {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my ($travels, $selected) = Db::getTravels;
    Db::disconnect();
    $self->stash(travels => $travels);
    $self->stash(selected => $selected);

    $self->render('admin/index');
}

sub login {
    my $self = shift;
    $self->render('admin/login');
}

sub validate {
    my $self = shift;
    my $user = $self->param('user');
    my $password = $self->param('password');
    my $redirect = '/error';

    if ($user eq 'sondre' and $password eq 'frihet') {
        $self->session(user => $user);
        $redirect = '/admin';
    } else {
        $self->flash(message => 'Feil brukernavn eller passord:///');
    }
    $self->redirect_to($redirect);
}

#sub remove {
#   my $self = shift;
#   Db::connect('blogg', 'tiro', 'kokid8Ei');

#   my $images = Db::getImages();
#   $self->stash(images => $images);
#   Db::disconnect();

#    Render template "example/welcome.html.ep" with message
#   $self->render();
#}

sub newTravel {
    my $self = shift;
    my $newTravel = $self->param('newtravel');

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    Db::cleanUpTravels();
    Db::addTravel($newTravel);
    Db::disconnect();

    $self->redirect_to('/admin');
}

sub uploadVideo {
    my $self = shift;
    my $tag = $self->param('tag');
    my $travel = $self->param('selectedTravel');
    my $videoid = $self->param('videoid');
    my $title= $self->param('title');

    $tag = "notag" if $tag eq "";
    $travel = "notravel" if $travel eq "";

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    Db::addVideo($title, $videoid, $tag, $travel);
    Db::setSelectedTravel($travel);
    Db::disconnect();

    $self->redirect_to('/');
}

sub upload {
    my $self = shift;
    my $tag = $self->param('tag');
    my $travel = $self->param('selectedTravel');
    my $commands = Mojolicious::Commands->new;

    $tag = "notag" if $tag eq "";
    $travel = "notravel" if $travel eq "";

    my @images = $self->req->upload('imagefiles[]');
    if ($images[0]->size == 0) {
        $self->flash(message => 'Du må velge minst en fil');
        $self->redirect_to('error');
    } 
    else {
        $commands->create_dir("public/images/$travel/$tag") 
                    unless -d "public/images/$travel/$tag/";
        $commands->create_dir("public/images/$travel/$tag/thumbs")
                    unless -d "public/images/$travel/$tag/thumbs";
        for my $image (@images) {
            my $file = $image->{'filename'};
            $image->move_to("public/images/$travel/$tag/$file");
        }
        make_thumbs($tag, $travel);
        Db::connect('blogg', 'tiro', 'kokid8Ei');
        Db::addImages(\@images, $tag, $travel);
        Db::setSelectedTravel($travel);
        Db::disconnect();


        $self->redirect_to('/');
    }
}

sub make_thumbs {
    my $tag = shift;
    my $travel = shift;
    my $dir = "public/images/$travel/$tag";

    my @pix = `ls $dir | egrep 'jpg|JPG|jpeg|JPEG'`;

    for my $pix (@pix) {
        chomp $pix;
        my ($name, $ending) = split('\.', $pix);
        say $ending;
        $name = join('', 'thumb_', $name);

        print "$pix -> $name.$ending \n";
        `convert $dir/$pix -thumbnail x200 -resize '200x<' -resize 50% -gravity center -crop 100x100+0+0 +repage -format jpg -quality 91 $dir/thumbs/$name.$ending`;
    }
}

1;
