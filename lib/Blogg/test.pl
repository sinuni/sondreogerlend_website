#!/usr/bin/perl -w
use strict;
use DBI;

my $db = 'blogg';
my $user = 'tiro';
my $pass = 'kokid8EI';

my $dbh = DBI->connect("dbi:Pg:dbname=$db", "$user", "$pass")
            or die "Cannot connect to database: $DBI::errstr\n";
my $sth = $dbh->prepare("SELECT name, date, tag FROM image");
$sth->execute or die "Cannot execute statment: $DBI::errstr\n";

my $frukt = {};
while (my ($name, $date, $tag) = $sth->fetchrow_array()) {
#   $frukt->{$date} = [{'name' => $name}];
#   print "$frukt->{$date}->[0]->{'name'}\n";
    print $name . "\n";
    $frukt->{$date};
    push(@{$frukt->{$date}}, {'name' => $name, 'tag' => $tag});
}
for my $date (keys %$frukt) {
    print $_->{'name'} for (@{$frukt->{$date}});
}
