#!/usr/bin/perl
use Mojo::Server::Hypnotoad;

my $toad = Mojo::Server::Hypnotoad->new;
#$toad->app->config(hypnotoad => {listen => ['http://*:80']});
$toad->run('./blogg');
