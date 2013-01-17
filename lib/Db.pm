package Db;

use DBI;
use utf8;
use Encode;

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

sub getPosts {
    my $sth = $dbh->prepare("SELECT id, name, date, tag, travel FROM post");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $posts = {};
    while (my ($id, $name, $date, $tag, $travel) = $sth->fetchrow_array()) {
        push @{$posts->{$date}}, {'id' => $id, 'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $posts;
}

sub addCommentToPost {
    die "addCommentToPost takes three arguments, \$postid, \\\$name and \\\$comment\n" unless @_ == 3;
    my ($postid, $name, $comment) = @_;

    my $sth = $dbh->prepare("INSERT INTO post_comment (postid, name, text, date, time) VALUES(?, ?, ?, now()::date, now()::time)")
        or die "Cannot prepare statment: $DBI::errstr\n";

    $sth->execute($postid, $$name, $$comment)
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

sub getVideos {
    my $sth = $dbh->prepare("SELECT name, videoid, date, tag, travel FROM video");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $videos = {};
    while (my ($name, $videoid, $date, $tag, $travel) = $sth->fetchrow_array()) {
        push @{$videos->{$date}}, {'name' => $name, 'videoid' => $videoid, 'tag' => $tag, 'travel' => $travel};
    }
    return $videos;
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

sub getImgDescriptions {
    die "getImgDescription takes two arguments, \$travel and \$tag\n" unless @_ == 2;
    my ($travel, $tag) = @_;

    my $sth = $dbh->prepare("SELECT name, description FROM image WHERE travel='$travel' and tag='$tag'");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $descriptions = {};
    while ( my ($name, $description) = $sth->fetchrow_array()) {
        $descriptions->{$name} = $description;
    }
    return $descriptions;
}

sub updateImgDescription {
    die "updateImgDescription takes two arguments, \$imgname and \$newdesc\n" unless @_ == 2;
    my ($imgname, $newdesc) = @_;
    print "$imgname and $newdesc\n";
    my $sth = $dbh->prepare("UPDATE image SET description='$newdesc' WHERE name='$imgname'")
        or die "Cannot prepare statment: $DBI::errstr\n";

    $sth->execute
        or die "Cannot execute statment: $DBI::errstr\n";
}

sub getImageDescription {
    die "getImgDescription takes two arguments, \$travel and \$filename\n" unless @_ == 2;
    my ($travel, $filename) = @_;

    my $sth = $dbh->prepare("SELECT description FROM image WHERE name='$filename' and travel='$travel'");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $desc = Encode::decode('UTF-8', $sth->fetchrow_array());

    return $desc;
}

sub getImagesFromTag {
    die "getImgaesFromTag takes one argument, \$tag\n" unless @_ == 1;
    my $tag = shift;

    my $sth = $dbh->prepare("SELECT name, date, tag, travel FROM image WHERE tag='$tag' order by name asc");
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

sub rmVideosByVideoIds {
    die "rmVideosByVideoIds takes one argument, \\\@videoids\n" unless @_ == 1;
    my $ids = shift;
    my $sth = $dbh->prepare("DELETE FROM video WHERE videoid=?")
        or die "Connot prepare statment: $DBI::errstr\n";
    
    foreach my $id (@$ids) {
        $sth->execute($id) or die "Cannot execute statment: $DBI::errstr\n";
    }
}

sub getImagesAndPosts {
    my $imgSth = $dbh->prepare("SELECT name, date, tag, travel FROM image order by date desc, name asc limit 50");
    $imgSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $postSth = $dbh->prepare("SELECT id, name, html,  date, tag, travel FROM post order by date desc, time desc limit 6");
    $postSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $videoSth = $dbh->prepare("SELECT name, videoid, date, tag, travel FROM video order by date desc, time desc limit 10");
    $videoSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $commentSth = $dbh->prepare("SELECT name, text, date, time FROM post_comment WHERE postid=?");

    my $elements = {};
    while (my ($id, $name, $html, $date, $tag, $travel) = $postSth->fetchrow_array()) {
        my $comments = [];
        push @{$elements->{$date}}, {'id' => $id, 'name' => $name, 'html' => $html, 'tag' => $tag, 'travel' => $travel, 'comments' => $comments};

        $commentSth->execute($id) or die "Cannot execute statment: $DBI::errstr\n";
        while (my ($name, $comment, $date, $time) = $commentSth->fetchrow_array()) {
            push @$comments, {'name' => $name, 'comment' => $comment, 'date' => $date, 'time' => $time};
        }
    }
    while (my ($name, $videoid, $date, $tag, $travel) = $videoSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'title' => $name, 'videoid' => $videoid, 'tag' => $tag, 'travel' => $travel};
    }
    while (my ($name, $date, $tag, $travel) = $imgSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $elements;
}

sub getImagesAndPostsByMonth {
    my $year = shift;
    my $month = shift;

    my $imgSth = $dbh->prepare("SELECT name, date, tag, travel 
                                FROM image
                                WHERE EXTRACT(month FROM \"date\") = $month
                                AND EXTRACT(year FROM \"date\") = $year
                                ORDER BY date desc, name asc");
    $imgSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $postSth = $dbh->prepare("SELECT id, name, html,  date, tag, travel
                                 FROM post
                                 WHERE EXTRACT(month FROM \"date\") = $month
                                 AND EXTRACT(year FROM \"date\") = $year
                                 ORDER BY date desc, time desc");
    $postSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $videoSth = $dbh->prepare("SELECT name, videoid, date, tag, travel
                                  FROM video
                                  WHERE EXTRACT(month FROM \"date\") = $month
                                  AND EXTRACT(year FROM \"date\") = $year
                                  ORDER BY date desc, time desc");
    $videoSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $commentSth = $dbh->prepare("SELECT name, text, date, time FROM post_comment WHERE postid=?");

    my $elements = {};
    while (my ($id, $name, $html, $date, $tag, $travel) = $postSth->fetchrow_array()) {
        my $comments = [];
        push @{$elements->{$date}}, {'id' => $id, 'name' => $name, 'html' => $html, 'tag' => $tag, 'travel' => $travel, 'comments' => $comments};

        $commentSth->execute($id) or die "Cannot execute statment: $DBI::errstr\n";
        while (my ($name, $comment, $date, $time) = $commentSth->fetchrow_array()) {
            push @$comments, {'name' => $name, 'comment' => $comment, 'date' => $date, 'time' => $time};
        }
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
