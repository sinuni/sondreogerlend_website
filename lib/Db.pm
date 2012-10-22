package Db;

use DBI;
use utf8;

my $dbh;

sub connect {
    my ($db, $user, $pass) = @_;

    $dbh = DBI->connect("dbi:Pg:dbname=$db", "$user", "$pass")
                or die "Cannot connect to database: $DBI::errstr\n";
}

sub disconnect {
    $dbh->disconnect();
}

sub addPost {
    die "addPost takes fore arguments, \\\$name \\\$html, \$tag and \$travel\n" unless @_ == 4;
    my ($name, $html, $tag, $travel) = @_;
    my $sth = $dbh->prepare("INSERT INTO post (name, html, date, tag, travel, time) VALUES(?, ?, now()::date, ?, ?, now()::time)")
        or die "Cannot prepare statment: $DBI::errstr\n";

    $sth->execute($$name, $$html, $tag, $travel)
        or die "Cannot execute statment: $DBI::errstr\n";
}

sub addVideo {
    die "addVideo takes fore arguments, \$title, \$videoid, \$tag and \$travel\n" unless @_ == 4;
    my ($title, $videoid, $tag, $travel) = @_;
    my $sth = $dbh->prepare("INSERT INTO video (name, videoid, date, tag, travel, time) VALUES(?, ?, now()::date, ?, ?, now()::time)")
        or die "Cannot prepare statment: $DBI::errstr\n";

    $sth->execute($title, $videoid, $tag, $travel)
        or die "Cannot execute statment: $DBI::errstr\n";
}

sub getNamesTagsAndTravels {
    die "getNamesAndTags takes one argument, \\\@names\n" unless @_ == 1;
    my $names = shift;
    my $sth = $dbh->prepare("SELECT name, tag, travel FROM image WHERE name=?")
        or die "Connot prepare statment: $DBI::errstr\n";
    print('---Check 3');
    
    my $images = [];
    foreach my $name (@$names) {
        $sth->execute($name);
        my ($name2, $tag, $travel) = $sth->fetchrow_array()
            or die "Cannot fetchrow_array: $DBI::errstr\n";
        push @$images, {'name' => $name2, 'tag' => $tag, 'travel' => $travel};
        print('---Check 4');
    }
    return $images;
}

sub rmImagesByName {
    die "rmImagesByName takes one argument, \\\@names\n" unless @_ == 1;
    my $images = shift;
    my $countSth = $dbh->prepare("SELECT count(*) FROM image WHERE name=?")
        or die "Connot prepare statment: $DBI::errstr\n";
    my $rmSth = $dbh->prepare("DELETE FROM image WHERE name=?")
        or die "Connot prepare statment: $DBI::errstr\n";

    foreach my $image ( @$images ) {
        my $name = $image;
        my $count = $countSth->execute($name)
            or die "Cannot execute statment: $DBI::errstr\n";
        if ($count == 1) {
            $rmSth->execute($name)
                or die "Cannot execute statment: $DBI::errstr\n";
        }
    }
}

sub addImages {
    die "addImages takes three arguments, \\\@names, \$tag and \$travel\n" unless @_ == 3;
    my ($images, $tag, $travel) = @_;
    my $sth = $dbh->prepare("INSERT INTO image (name, date, tag, travel) VALUES(?, now()::date, ?, ?)")
        or die "Cannot prepare statment: $DBI::errstr\n";

    foreach my $image ( @$images ) {
        my $name = $image->{'filename'};
        $sth->execute($name, $tag, $travel)
            or die "Cannot execute statment: $DBI::errstr\n";
    }
}

sub getImages {
    my $sth = $dbh->prepare("SELECT name, date, tag, travel FROM image");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $images = {};
    while (my ($name, $date, $tag, $travel) = $sth->fetchrow_array()) {
        push @{$images->{$date}}, {'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $images;
}

sub getImagesFromTag {
    die "getImgaesFromTag takes one argument, \$tag\n" unless @_ == 1;
    my $tag = shift;

    my $sth = $dbh->prepare("SELECT name, date, tag, travel FROM image WHERE tag='$tag'");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $images = {};
    while (my ($name, $date, $tag, $travel) = $sth->fetchrow_array()) {
        push @{$images->{$date}}, {'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $images;
}

# Bør byttes ut med noe som bare henter ut et elment per tag. Kanskje legge til en kolonne i databsen f. eks. album-front-bilde
sub getImagesForEachTag {
    my $sth = $dbh->prepare("SELECT name, tag, travel FROM image");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $images = {};
    while (my ($name, $tag, $travel) = $sth->fetchrow_array()) {
        push @{$images->{$tag}}, {'name' => $name, 'travel' => $travel};
    }
    return $images;
}

sub getPosts {
    my $sth = $dbh->prepare("SELECT id, name, date, tag, travel FROM post");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $posts = {};
    while (my ($id, $name, $date, $tag, $travel) = $sth->fetchrow_array()) {
        push @{$posts->{$date}}, {'id' => $id, 'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $posts;
    
}

sub getHtmlFromPostId {
    die "getHtmlFromPostId takes one argument, \\\@ids\n" unless @_ == 1;
    my $ids = shift;
    my $sth = $dbh->prepare("SELECT html FROM post WHERE id=?");

    my $posts = {};
    foreach my $id (@$ids) {
        $sth->execute($id) or die "Cannot execute statment: $DBI::errstr\n";
        my $html = $sth->fetchrow_array();
        $posts->{$id} = $html;
        print "$html\n";
    }
    return $posts;
}

sub rmPostsByIds {
    die "rmPostById takes one argument, \\\@ids\n" unless @_ == 1;
    my $ids = shift;
    my $sth = $dbh->prepare("DELETE FROM post WHERE id=?")
        or die "Connot prepare statment: $DBI::errstr\n";
    
    foreach my $id (@$ids) {
        $sth->execute($id) or die "Cannot execute statment: $DBI::errstr\n";
    }
}

sub getImagesAndPosts {
    my $imgSth = $dbh->prepare("SELECT name, date, tag, travel FROM image");
    $imgSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $postSth = $dbh->prepare("SELECT name, html,  date, tag, travel FROM post order by time desc");
    $postSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $videoSth = $dbh->prepare("SELECT name, videoid, date, tag, travel FROM video order by time desc");
    $videoSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $elements = {};
    while (my ($name, $html, $date, $tag, $travel) = $postSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'name' => $name, 'html' => $html, 'tag' => $tag, 'travel' => $travel};
    }
    while (my ($name, $videoid, $date, $tag, $travel) = $videoSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'title' => $name, 'videoid' => $videoid, 'tag' => $tag, 'travel' => $travel};
    }
    while (my ($name, $date, $tag, $travel) = $imgSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $elements;
}

sub getTravels {
    my $sth = $dbh->prepare("SELECT name, selected FROM travel");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $travels = [];
    my $selected;
    while (my ($travel, $sel) = $sth->fetchrow_array()) {
        push @$travels, $travel;
        $selected = $travel if $sel eq '1';
    }
    return $travels, $selected;
}

sub cleanUpTravels {
    my $sth = $dbh->prepare("SELECT name, selected FROM travel");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $travels = [];
    while (my ($travel, $sel) = $sth->fetchrow_array()) {
        push @$travels, $travel;
    }
    
    # Bør utvides til å sjekke om travelen brukes andre steder enn bare image. Enda en foreach.
    $sth = $dbh->prepare("SELECT count(*) FROM image where travel=?");
    foreach my $travel ( @$travels ) {
        $sth->execute($travel) or die "Cannot execute statment: $DBI::errstr\n";
        if( $sth->fetchrow_array() == 0) {
            my $delsth = $dbh->prepare("DELETE FROM travel where name=?");
            $delsth->execute($travel) or die "Cannot execute statment: $DBI::errstr\n";
        }
    }
}

sub setSelectedTravel {
    die "addTravel takes one argument\n" unless @_ == 1;
    my $travel = shift;

    my $sth = $dbh->prepare("UPDATE travel SET selected='false' WHERE selected='true'");
    $sth->execute() or die "Cannot execute statment: $DBI::errstr\n";

    $sth = $dbh->prepare("UPDATE travel SET selected='true' WHERE name=?");
    $sth->execute($travel) or die "Cannot execute statment: $DBI::errstr\n";
}

sub addTravel {
    die "addTravel takes one argument\n" unless @_ == 1;
    my $travel = shift;

    my $sth = $dbh->prepare("UPDATE travel SET selected='false' WHERE selected='true'");
    $sth->execute() or die "Cannot execute statment: $DBI::errstr\n";
    
    my $sth = $dbh->prepare("INSERT INTO travel (name, selected) VALUES(?,'true')");
    $sth->execute($travel) or die "Cannot execute statment: $DBI::errstr\n";
}

1;
