#!/usr/bin/perl

use strict;
use Test;
BEGIN { plan tests => 2, todo => [] }

use String::Escape qw( printable unprintable escape );

my ( $original, $printable, $comparison );

# Backslash escapes for newline and tab characters

$original = "\tNow is the time\nfor all good folk\nto party.\n";
$comparison = '\\tNow is the time\\nfor all good folk\\nto party.\\n';

ok( escape('qprintable', $original) eq '"' . $comparison . '"' );

# Can pass in function references

my $running_total;
ok( (escape( sub { $running_total += shift; }, 23, 4, 2, 13))[3] == 42 );
