#!/usr/bin/perl -w
use strict;
use v5.10.0;

my $elements = {
    '2012-12-24' => [ { 'type'      => 'pic',
                        'filename'  => 'banan1.jpg',
                        'tag'       => 'frukt' },
                      { 'type'      => 'pic',
                        'filename'  => 'banan2.jpg',
                        'tag'       => 'frukt' } ],

    '2013-01-12' => [ { 'type'      => 'pic',
                        'filename'  => 'eple.jpg',
                        'tag'       => 'frukt' } ],

    '2012-12-26' => [ { 'type'      => 'text',
                        'text'      => 'Hei og hallo',
                        'tag'       => 'frukt' } ]
            };

foreach my $date (sort keys %$elements) {
    print "$date\n";

    foreach my $elm ( @{$elements->{$date}} ) {
        say "   " . $elm->{'filename'} if $elm->{'type'} eq 'pic';
        say "   " . $elm->{'text'} if $elm->{'type'} eq 'text';
    }
}
