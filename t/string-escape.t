#!/usr/bin/perl

use strict;
use Test;
BEGIN { plan tests => 5, todo => [] }

use String::Escape qw( printable unprintable escape );

my ( $original, $printable, $comparison );

# Backslash escapes for newline and tab characters

$original = "\tNow is the time\nfor all good folk\nto party.\n";
$printable = printable( $original );
$comparison = '\\tNow is the time\\nfor all good folk\\nto party.\\n';

ok( $printable eq $comparison);

# Backslash escaping with double quotes

ok( escape('qprintable', $original) eq '"' . $comparison . '"' );

# Expand backslash escapes

$comparison = unprintable( $printable );

ok( $comparison eq $original );

# Should work for high-bit characters as well

$original = " this\nis a¼ ªtest.º \\quote\\ endquote.";
$printable = printable( $original );
$comparison = unprintable( $printable );

ok( $comparison eq $original );

# Can pass in function references

my $running_total;
ok( (escape( sub { $running_total += shift; }, 23, 4, 2, 13))[3] == 42 );
