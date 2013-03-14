package Blogg::Admin::Imgbrowser;
use Mojo::Base ('Mojolicious::Controller');
use Db;
use utf8;

sub index {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    my $startDir = "/images/Friaar/";

#   $self->app->log->debug(getFolders("/"));
#   $self->app->log->debug(getFiles("/"));
    my $content = { folders => getFolders($startDir), files => getFiles($startDir) };
    $self->stash(content => $content);

    $self->render('/admin/imgbrowser');
}

sub changeDir {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    my $newpath = $self->param('newpath');

    my $content = { folders => getFolders($newpath), files => getFiles($newpath) };

    $self->render(json => $content);
}

sub updateDescription {
    my $self = shift;
    $self->redirect_to('/admin/login') unless $self->session('user');

    my $imgname = $self->param('filename');
    my $newdesc = $self->param('description');
    my $response;

    if( length $newdesc > 300 ) {
        $response = {tolong => 1, message => "Det var en for lang description. Max 300 tegn:-D"};
    } else {
        Db::connect('blogg', 'tiro', 'kokid8Ei');
        $response = Db::updateImgDescription($imgname, $newdesc);
        Db::disconnect();
    }

    $self->render(json => $response);
}

sub getFolders {
    my $dir = shift;

    my @folders = `ls -d public$dir*/`;
    my $json = [];
    unshift @folders, ".." if length $dir > 1;
    for ( @folders ) {
        s/^.*\/([^\/]*)\/$/$1/;
        chomp;
        push @$json, { "name" => $_ };
     }

    return $json;
}

sub getFiles {
    my $dir = shift;
    my @files = `ls -F public$dir | grep -v /`;
    my $json = [];
    my ($travel, $tag) = ($1, $2) if $dir =~ m/^\/images\/([^\/]*)\/([^\/]*)\/$/; 

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    my $descriptons = Db::getImgDescriptions($travel, $tag);
    Db::disconnect();

    for my $file ( @files ) {
        my $temp = {};
        chomp $file;
        $temp->{'name'} = $file;

        if ($file =~ m/\.jpg/i and $dir =~ m/^\/images\/([^\/]*)\/([^\/]*)\/$/) {
            $temp->{'type'} = "image";
            $temp->{'thumb'} = "/images/$1/$2/thumbs/thumb_$file";
            $temp->{'description'} = $descriptons->{$file}; 
        } else {
            $temp->{'type'} = "file";
        }
        push @$json, $temp;
    }

    return $json;
}

sub addFolder {
    my $self = shift;
    my $commands = Mojolicious::Commands->new;
    my $newFolder = $self->param('name');
    my @path = $self->param('path[]');

    my $newDir = "/";
    $newDir .= $_."/" for @path;
    $newDir .= $newFolder;

    $commands->create_dir("public/$newDir")
                unless -d "public/$newDir";

    $self->render(json => 'virk');
}

sub setTravelCover {
    my $self = shift;
    my $travel = $self->param('travel');
    my $tag =$self->param('tag');
    my $image =$self->param('filename');

#   $self->app->log->debug("travel: $travel tag: $tag image: $image");
    my $file = "public/images/$travel/$tag/$image";
    if(`identify $file` =~ /^(.*\.JPG)[^ ]* JPEG (\d*)x(\d*) [^ ]* [^ ]* [^ ]* ([^ ]*)/i) {
        my $width = $2;
        my $height = $3;

        if( $height > $width ) {
            `convert $file -resize 180 -gravity center -crop 180x111+0+0 +repage -format jpg -quality 92 public/images/$travel/travel_cover/cover_image.jpg`;
        } else {
            `convert $file -resize x111 -gravity center -crop 180x111+0+0 +repage -format jpg -quality 92 public/images/$travel/travel_cover/cover_image.jpg`;
        }
    }
#   `convert public/images/$travel/$tag/$image -resize 180 -resize 'x111<' -gravity center -crop 180x111+0+0 +repage -format jpg -quality 92 public/images/$travel/cover_image.jpg`;

    $self->render(json => 'done');
}

sub setAlbumCover {
    my $self = shift;
    my $travel = $self->param('travel');
    my $tag =$self->param('tag');
    my $image =$self->param('filename');

#   $self->app->log->debug("travel: $travel tag: $tag image: $image");
    my $file = "public/images/$travel/$tag/$image";
    if(`identify $file` =~ /^(.*\.JPG)[^ ]* JPEG (\d*)x(\d*) [^ ]* [^ ]* [^ ]* ([^ ]*)/i) {
        my $width = $2;
        my $height = $3;

        if( $height > $width ) {
            `convert $file -resize 150 -gravity center -crop 150x150+0+0 +repage -format jpg -quality 92 public/images/$travel/$tag/album_cover/cover_image.jpg`;
        } else {
            `convert $file -resize x150 -gravity center -crop 150x150+0+0 +repage -format jpg -quality 92 public/images/$travel/$tag/album_cover/cover_image.jpg`;
        }
    }

    $self->render(json => 'done');
}

sub uploadImages{
    my $self = shift;
    my $tag = $self->param('tag');
    my $travel = $self->param('travel');
    my $commands = Mojolicious::Commands->new;

    my @images = $self->req->upload('imagefiles[]');
    if ($images[0]->size == 0) {
        $self->flash(message => 'Du må velge minst en fil');
        $self->redirect_to('error');
    } 
    else {
#       $commands->create_dir("public/images/$travel/$tag") 
#                   unless -d "public/images/$travel/$tag/";
        $commands->create_dir("public/images/$travel/$tag/thumbs")
                    unless -d "public/images/$travel/$tag/thumbs";
        for my $image (@images) {
            my $file = $image->{'filename'};
            $image->move_to("public/images/$travel/$tag/$file");
        }
        make_thumbs($tag, $travel);
        Db::connect('blogg', 'tiro', 'kokid8Ei');
        Db::addImages(\@images, $tag, $travel);
#       Db::setSelectedTravel($travel);
        Db::disconnect();
#       $self->app->log->debug("travel: $travel tag: $tag");


        $self->render(json => 'virk');
    }
}

sub removeImages{
    my $self = shift;

    my $travel = $self->param('travel');
    my $tag = $self->param('tag');
    my @images = $self->param('images[]');
#   $self->app->log->debug("travel: $travel, tag: $tag");
    
    foreach my $image ( @images ) {
       `rm public/images/$travel/$tag/$image`; 
       `rm public/images/$travel/$tag/thumbs/thumb_$image`; 
#       $self->app->log->debug("image: $image");

       my @remindings = `ls -A public/images/$travel/$tag/thumbs`;
       if (@remindings == 0) {
            `rm -rf public/images/$travel/$tag`;     
       }
    }

    Db::connect('blogg', 'tiro', 'kokid8Ei');
    Db::rmImagesByName(\@images);
    Db::disconnect();

    $self->render(json => 'virk');
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

#       print "$pix -> $name.$ending \n";
        `convert $dir/$pix -thumbnail x200 -resize '200x<' -resize 50% -gravity center -crop 100x100+0+0 +repage -format jpg -quality 91 $dir/thumbs/$name.$ending`;
    }
}

1;
