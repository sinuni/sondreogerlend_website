package Db;

use DBI;
use utf8;
use Encode;
use POSIX qw(strftime);
use Date::Manip;

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
    die "addPost takes fore arguments, \\\$name \\\$html, \$tag, \$travel, \$latitude and \$longitude\n" unless @_ == 6;
    my ($name, $html, $tag, $travel, $lat, $lng) = @_;
    my $sth = $dbh->prepare("INSERT INTO post (name, html, date, tag, travel, time, latitude, longitude) VALUES(?, ?, now()::date, ?, ?, now()::time, ?, ?)")
        or die "Cannot prepare statment: $DBI::errstr\n";

    $sth->execute($$name, $$html, $tag, $travel, $lat, $lng)
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

sub getPostById {
    $postid = shift;
    my $postSth = $dbh->prepare("SELECT name, html, date, tag FROM post WHERE id=?");
    $postSth->execute($postid) or die "Cannot execute statment: $DBI::errstr\n";

    my ($name, $html, $date, $tag) = $postSth->fetchrow_array();
    my $http_date = UnixDate(ParseDate("$date"), "%a, %d %b %Y");

    my $commentSth = $dbh->prepare("SELECT name, text, date, time FROM post_comment WHERE postid=?");
    $commentSth->execute($postid) or die "Cannot execute statment: $DBI::errstr\n";
    
    my $comments = [];
    while (my ($name, $comment, $date, $time) = $commentSth->fetchrow_array()) {
        my $http_date = UnixDate(ParseDate("$date"), "%a, %d %b %Y");
        my $name = Encode::decode('UTF-8', $name);
        my $comment = Encode::decode('UTF-8', $comment);
        push @$comments, {'name' => $name, 'comment' => $comment, 'http_date' => $http_date, 'time' => $time};
    }
    my $post = {'name' => $name, 'html' => $html, 'http_date' => $http_date, 'tag' => $tag, 'comments' => $comments};
    
    return $post;
}

sub getMapData {
    my $travel = shift;
    my $sth = $dbh->prepare("SELECT id, name, latitude, longitude FROM post WHERE travel=?");
    $sth->execute($travel) or die "Cannot execute statment: $DBI::errstr\n";

    my $latLngs = [];
    my $posts = [];
    while (my ($id, $name, $lat, $lng) = $sth->fetchrow_array()) {
        push @$latLngs, {'lat' => $lat, 'lng' => $lng};
        push @$posts, {'id' => $id, 'name' => $name};
    }
    return {'posts' => $posts, 'latLngs' => $latLngs};
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
    
    my $images = [];
    foreach my $name (@$names) {
        $sth->execute($name);
        my ($name2, $tag, $travel) = $sth->fetchrow_array()
            or die "Cannot fetchrow_array: $DBI::errstr\n";
        push @$images, {'name' => $name2, 'tag' => $tag, 'travel' => $travel};
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
        $descriptions->{$name} = Encode::decode('UTF-8', $description);
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
    die "getImgDescription takes one arguments, \$imageid\n" unless @_ == 1;
    my $imageid = shift;

    my $sth = $dbh->prepare("SELECT description FROM image WHERE id='$imageid'");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $desc = Encode::decode('UTF-8', $sth->fetchrow_array());

    return $desc;
}

sub getImageComments{
    die "getImgComments takes one arguments, \$imageid\n" unless @_ == 1;
    my $imageid = shift;

    my $sth = $dbh->prepare("SELECT name, text FROM image_comment WHERE imageid='$imageid'");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $comments = [];
    while (my ($name, $text) = $sth->fetchrow_array()) {
        push @$comments, { name => $name, text => $text };
    }

    return $comments;
}

sub addCommentToImage{
    die "addCommentToImage takes three arguments, \$imageid, \$name and \$comment\n" unless @_ == 3;
    my ($imageid, $name, $comment) = @_;

    my $sth = $dbh->prepare("INSERT INTO image_comment (imageid, name, text, date, time) VALUES(?, ?, ?, now()::date, now()::time)")
        or die "Cannot prepare statment: $DBI::errstr\n";
    $sth->execute($imageid, $name, $comment)
        or die "Cannot execute statment: $DBI::errstr\n";
}

sub getImagesFromTag {
    die "getImgaesFromTag takes one argument, \$tag\n" unless @_ == 1;
    my $tag = shift;

    my $sth = $dbh->prepare("SELECT id, name, date, tag, travel FROM image WHERE tag='$tag' order by name asc");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $images = [];
    while (my ($id, $name, $date, $tag, $travel) = $sth->fetchrow_array()) {
        push @$images, {'id' => $id, 'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $images;
}

# Bør byttes ut med noe som bare henter ut et elment per tag. Kanskje legge til en kolonne i databsen f. eks. album-front-bilde
sub getImagesForEachTravel{
    my $sth = $dbh->prepare("SELECT name, tag, travel FROM image");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $images = {};
    while (my ($name, $tag, $travel) = $sth->fetchrow_array()) {
        push @{$images->{$travel}}, {'name' => $name, 'tag' => $tag};
    }
    return $images;
}

sub getInfoForEachTravel {
    my $travelSth = $dbh->prepare("SELECT name FROM travel");
    $travelSth->execute or die "Cannot execute statment: $DBI::errstr\n";
    my $imgSth = $dbh->prepare("SELECT COUNT(*) FROM image WHERE travel=?");
    my $postSth = $dbh->prepare("SELECT COUNT(*) FROM post WHERE travel=?");
    my $firstSth = $dbh->prepare("SELECT MIN(date) FROM post WHERE travel=?");
    my $lastSth = $dbh->prepare("SELECT MAX(date) FROM post WHERE travel=?");
    
    my $travels = [];
    while(my $name = $travelSth->fetchrow_array()) {
        $imgSth->execute($name) or die "Cannot execute statment: $DBI::errstr\n";
        $postSth->execute($name) or die "Cannot execute statment: $DBI::errstr\n";
        $firstSth->execute($name) or die "Cannot execute statment: $DBI::errstr\n";
        $lastSth->execute($name) or die "Cannot execute statment: $DBI::errstr\n";
        my $image_count = $imgSth->fetchrow_array();
        my $post_count = $postSth->fetchrow_array();
        my $first_date = $firstSth->fetchrow_array();
        my $last_date = $lastSth->fetchrow_array();
        $first_date = UnixDate(ParseDate($first_date), "%a, %d %b %Y");
        $last_date = UnixDate(ParseDate($last_date), "%a, %d %b %Y");

        push @$travels, {'name' => $name, 'image_count' => $image_count, 'post_count' => $post_count, 'first_date' => $first_date, 'last_date' => $last_date};
    }

    return $travels;
}

# Bør byttes ut med noe som bare henter ut et elment per tag. Kanskje legge til en kolonne i databsen f. eks. album-front-bilde
sub getImagesForEachTag {
    die "getImgaesForEachTag takes one argument, \$travel\n" unless @_ == 1;
    my $travel = shift;

    my $sth = $dbh->prepare("SELECT name, tag, travel FROM image WHERE travel='$travel'");
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
    my $imgSth = $dbh->prepare("SELECT id, name, date, tag, travel FROM image order by date desc, name asc limit 50");
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
    while (my ($id, $name, $date, $tag, $travel) = $imgSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'id' => $id, 'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $elements;
}

sub getImagesAndPostsByMonth {
    my $year = shift;
    my $month = shift;

    my $imgSth = $dbh->prepare("SELECT id, name, date, tag, travel 
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
    while (my ($id, $name, $date, $tag, $travel) = $imgSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'id' => $id, 'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }
    return $elements;
}

sub getImagesAndPostsByPageAndTravel{
    my $page = shift;
    my $travel = shift;
    my $postsPrPage = 4;
    my $dateNow = strftime "%Y-%m-%d", localtime;
    my $dateOld = "2012-06-01";
    my $posts;   # Antall poster

    # Get number of posts for this travel
    my $postsSth = $dbh->prepare("SELECT count(*) FROM (SELECT date FROM post WHERE travel='$travel' GROUP BY date) foo");
    $postsSth->execute() or die "Cannot execute statment: $DBI::errstr\n";
    $posts = $postsSth->fetchrow_array();

    # Extract the date range covering this page
    my $startDate = $dateOld;
    my $endDate = $dateOld;
    # extract date of desired row number
    my $dateSth = $dbh->prepare("SELECT date FROM (SELECT date, row_number() over (ORDER BY date desc) rn from post WHERE travel=? GROUP BY date) AS rows WHERE rn=?");
    if($page == 1 and $posts <= $postsPrPage) {
        $startDate = $dateNow;
        $endDate = $dateOld;
    } elsif($page == 1 and $posts > $postPrPage) {
        $startDate = $dateNow;
        $dateSth->execute($travel, $postsPrPage) or die "Cannot execute statment: $DBI::errstr\n";
        $endDate = $dateSth->fetchrow_array();
    } elsif($page * $postsPrPage >= $posts and $page * $postsPrPage < $posts + $postsPrPage) {
        $dateSth->execute($travel, ($page-1)*$postsPrPage+1) or die "Cannot execute statment: $DBI::errstr\n";
        $startDate = $dateSth->fetchrow_array();
        $endDate = $dateOld;
    } elsif($page > 1 and $page * $postsPrPage < $posts) {
        $dateSth->execute($travel, ($page-1)*$postsPrPage+1) or die "Cannot execute statment: $DBI::errstr\n";
        $startDate = $dateSth->fetchrow_array();
        $dateSth->execute($travel, $page*$postsPrPage) or die "Cannot execute statment: $DBI::errstr\n";
        $endDate = $dateSth->fetchrow_array();
    }
    
    # Extract the data
    my $imgSth = $dbh->prepare("SELECT id, name, date, tag, travel 
                                FROM image
                                WHERE date <= '$startDate'
                                AND date >= '$endDate'
                                AND travel = '$travel'
                                ORDER BY date desc, name asc");
    $imgSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $postSth = $dbh->prepare("SELECT id, name, html,  date, tag, travel
                                 FROM post
                                 WHERE date <= '$startDate'
                                 AND date >= '$endDate'
                                 AND travel = '$travel'
                                 ORDER BY date desc, time desc");
    $postSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $videoSth = $dbh->prepare("SELECT name, videoid, date, tag, travel
                                  FROM video
                                  WHERE date <= '$startDate'
                                  AND date >= '$endDate'
                                  AND travel = '$travel'
                                  ORDER BY date desc, time desc");
    $videoSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $commentSth = $dbh->prepare("SELECT name, text, date, time FROM post_comment WHERE postid=?");

    # Package the data
    my $elements = {};
    while (my ($id, $name, $html, $date, $tag, $travel) = $postSth->fetchrow_array()) {
        my $comments = [];
        my $http_date = UnixDate(ParseDate("$date"), "%a, %d %b %Y");
        push @{$elements->{$date}}, {'id' => $id, 'name' => $name, 'html' => $html, 'http_date' => $http_date, 'tag' => $tag, 'travel' => $travel, 'comments' => $comments};

        $commentSth->execute($id) or die "Cannot execute statment: $DBI::errstr\n";
        while (my ($name, $comment, $date, $time) = $commentSth->fetchrow_array()) {
            $http_date = UnixDate(ParseDate("$date"), "%a, %d %b %Y");
            my $name = Encode::decode('UTF-8', $name);
            my $comment = Encode::decode('UTF-8', $comment);
            push @$comments, {'name' => $name, 'comment' => $comment, 'http_date' => $http_date, 'date' => $date, 'time' => $time};
        }
    }
    while (my ($name, $videoid, $date, $tag, $travel) = $videoSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'title' => $name, 'videoid' => $videoid, 'tag' => $tag, 'travel' => $travel};
    }
    while (my ($id, $name, $date, $tag, $travel) = $imgSth->fetchrow_array()) {
        push @{$elements->{$date}}, {'id' => $id, 'name' => $name, 'tag' => $tag, 'travel' => $travel};
    }

    my $data = {'elements' => $elements, 'pages' => $posts % $postsPrPage == 0 ? $posts / $postsPrPage : int($posts / $postsPrPage) + 1};
    return $data;
}

sub getPostsWithPagenr {
    my $postSth = $dbh->prepare("SELECT id, name, html,  date, time, tag, travel FROM post order by date desc, time desc");
    $postSth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $posts = [];
    my $postPrPage = 4;
    my $pageNr = 1;
    my $prevDate = "";
    my $prevTravel = "";
    my $postCounter = 1;
    while (my ($id, $name, $html, $date, $time, $tag, $travel) = $postSth->fetchrow_array()) {
        if($prevTravel ne $travel and $prevTravel ne "") {
            $pageNr = 1;
            $postCounter = 1;
            $prevDate = undef;
        }
        $prevTravel = $travel;
        if($prevDate ne $date and $prevDate ne "") {
            $postCounter++;
        }
        $prevDate = $date;
        if($postCounter > $postPrPage) {
            $pageNr++;
            $postCounter = 1;
        }

        my $tempDate = "$date $time";
        Date_Init("TZ=CET");
        my $http_date = UnixDate(ParseDate("$tempDate"), "%a, %d %b %Y %H:%M:%S %Z");

#       print "date: $tempDate http_date: $http_date\n";

        push @$posts, {'id' => $id, 'name' => $name, 'html' => $html, 'date' => $date, 'http_date' => $http_date, 'tag' => $tag, 'travel' => $travel, 'pagenr' => $pageNr};
    }

    return $posts;
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

sub getTags {
    my $travel = shift;
    my $sth = $dbh->prepare("SELECT tag FROM (SELECT MIN(date), tag FROM image WHERE travel=? GROUP BY tag) AS d ORDER BY d ASC");
    $sth->execute($travel) or die "Cannot execute statment: $DBI::errstr\n";

    my $tags = [];
    while (my $tag = $sth->fetchrow_array()) {
        push @$tags, $tag;
    }
    return $tags;
}

sub getActiveTravel {
    my $sth = $dbh->prepare("SELECT name, selected FROM travel");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $selected;
    while (my ($travel, $sel) = $sth->fetchrow_array()) {
        $selected = $travel if $sel eq '1';
    }
    return $selected;
}

sub cleanUpTravels {
    my $sth = $dbh->prepare("SELECT name, selected FROM travel");
    $sth->execute or die "Cannot execute statment: $DBI::errstr\n";

    my $travels = [];
    while (my ($travel, $sel) = $sth->fetchrow_array()) {
        push @$travels, $travel;
    }
    
    # Bør utvides til å sjekke for videoer også
    $imgSth = $dbh->prepare("SELECT count(*) FROM image where travel=?");
    $postSth = $dbh->prepare("SELECT count(*) FROM post where travel=?");
    foreach my $travel ( @$travels ) {
        $imgSth->execute($travel) or die "Cannot execute statment: $DBI::errstr\n";
        $postSth->execute($travel) or die "Cannot execute statment: $DBI::errstr\n";
        if( $imgSth->fetchrow_array() == 0 and $postSth->fetchrow_array() == 0) {
            my $delsth = $dbh->prepare("DELETE FROM travel WHERE name=?");
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
