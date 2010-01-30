#!/usr/bin/perl

use strict;

use Test::More( tests => 22 );

BEGIN { 
	use_ok( 'String::Escape', qw( evalable unevalable qevalable unqevalable ) ) 
}

{ 
	# Backslash escapes for newline and tab characters

	my $original = "\tNow is the time\nfor all good folk\nto party.\n";
	my $expected = '\\tNow is the time\\nfor all good folk\\nto party.\\n';

	is( evalable( $original ) => $expected );
	is( unevalable( $expected ) => $original );
	is( eval( qq{"$expected"} ) => $original );
}

{ 
	# Backslash escapes for newline and tab characters

	my $original = "\tNow is the time\nfor all good folk\nto party.\n";
	my $expected = '"\\tNow is the time\\nfor all good folk\\nto party.\\n"';

	is( qevalable( $original ) => $expected );
	is( unqevalable( $expected ) => $original );
	is( eval( $expected ) => $original );
}

{ 
	# Handles empty strings

	my $original = "";

	is( evalable( $original ) => $original );
	is( unevalable( $original ) => $original );
}

{ 
	# Handles backslashes in strings

	my $original = "four \\ three";
	my $expected = '"four \\\\ three"';

	is( eval( $expected ) => $original );
	is( qevalable( $original ) => $expected );
	is( unqevalable( $expected ) => $original );
	is( eval( qevalable( $original ) ) => $original );
}

{ 
	# Support for octal and hex escapes

	my $original = "this\tis\ta\011string\x09with some text\r\n";
	my $expected = '"this\\tis\\ta\\tstring\\twith some text\\r\\n"';

	is( qevalable( $original ) => $expected );
	is( unqevalable( $expected ) => $original );
	is( eval( $expected ) => $original );
}

{ 
	# Handles undef

	my $original = undef;
	my $expected = "";

	is( evalable( $original ) => $expected );
	is( unevalable( $original ) => $expected );
}

{ 
	# Should work for high-bit characters as well

	my $original = " this\nis a¼ ªtest.º \\quote\\ endquote.";
	my $expected = '" this\\nis a\xbc \\xaatest.\\xba \\\\quote\\\\ endquote."';

	is( qevalable( $original ) => $expected );
	is( unqevalable( $expected ) => $original );
	is( unevalable( evalable( $original ) ) => $original );
	is( eval( $expected ) => $original );
}
