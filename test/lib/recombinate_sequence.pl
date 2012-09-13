#!/usr/bin/env perl
use warnings FATAL => 'all';
use strict;

use IO::Handle;
use Getopt::Long;
use Pod::Usage;

GetOptions(
    'help'        => sub { pod2usage( -verbose   => 1 ) },
    apply_cre     => \my $apply_cre,
    apply_flp     => \my $apply_flp,
    apply_flp_cre => \my $apply_flp_cre,
) or pod2usage(2);

my $stream = *ARGV;

while (  my $seq = <$stream> ) {
    my $modified_seq;
    if ( $apply_cre ) {
        $modified_seq = $seq;
    }
    elsif ( $apply_flp ) {
        $modified_seq = $seq;
    }
    elsif ( $apply_flp_cre ) {
        $modified_seq = $seq;
    }
    else {
        pod2usage( 'Must specify a recombinse to apply' );
    }

    print $modified_seq;
}