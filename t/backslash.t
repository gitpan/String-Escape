#!/usr/bin/perl

use strict;
use Test;
BEGIN { plan tests => 3, todo => [] }

use String::Escape qw( printable unprintable );

my ( $original, $printable, $comparison );

# Backslash escapes for newline and tab characters

$original = "\tNow is the time\nfor all good folk\nto party.\n";
$printable = printable( $original );
$comparison = '\\tNow is the time\\nfor all good folk\\nto party.\\n';

ok( $printable eq $comparison);

$comparison = unprintable( $printable );
ok( $comparison eq $original );

# Should work for high-bit characters as well

$original = " this\nis a¼ ªtest.º \\quote\\ endquote.";
$printable = printable( $original );
$comparison = unprintable( $printable );

ok( $comparison eq $original );
