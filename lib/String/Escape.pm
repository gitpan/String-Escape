### String::Escape - Registry of string functions, including backslash escapes

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### To Do:
  # - Compare with TOMC's String::Edit package.

### Change History
  # 1998-09-19 Support for function and array references in expand_escape_spec.
  # 1998-09-01 Fixed return value from expand_escape_spec.
  # 1998-07-31 Rewrote (un)qprintable to just call other functions in order.
  # 1998-07-30 Expanded POD to cover use of new Makefile.PL.
  # 1998-07-23 Conventionalized POD, switched to yyyy.mm_dd version numbering.
  # 1998-06-11 Modified printable and unprintable algorithms to use hash map.
  # 1998-04-27 Anchored regexes in unprintable() to fix backslash mangling.
  # 1998-03-16 Avoid constant modification via lexical rather than $_. -Simon
  # 1998-02-25 Version 1.00 - String::Escape
  # 1998-02-25 Moved to String:: and @EXPORT_OK for CPAN distribution - jeremy
  # 1998-02-19 Started removal of sub add calls throughout Evo::Script
  # 1997-10-28 Created generic by-name interface; renamed printable().
  # 1997-10-21 Altered quote_non_words regex to accept '-', '/', and '.'
  # 1997-08-17 Created this package from functions in dictionary.pm. -Simon

package String::Escape;

require 5;
use strict;
use Carp;

use vars qw( $VERSION @ISA @EXPORT_OK );
$VERSION = 1998.09_19;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( escape printable unprintable );
push @EXPORT_OK, qw( quote unquote quote_non_words qprintable unqprintable );

### Call by-name interface

# %Escapes - escaper function references by name
use vars qw( %Escapes );
%Escapes = (
  %Escapes,
  'none' =>        sub ($) { $_[0]; },
  
  'uppercase' =>   sub ($) { uc $_[0] },
  'lowercase' =>   sub ($) { lc $_[0] },
  'initialcase' => sub ($) { ucfirst lc $_[0] },
  
  'quote' => \&quote,
  'unquote' => \&unquote,
  'quote_non_words' => \&quote_non_words,
  
  'printable' => \&printable,
  'unprintable' => \&unprintable,
  
  'qprintable' => 'printable quote_non_words',
  'unqprintable' => 'unquote unprintable',
);

# String::Escape::add( $name, $subroutine );
sub add ($$) { $Escapes{ shift(@_) } = shift(@_); }

# @defined_names = String::Escape::names();
sub names () { keys(%Escapes); }

# @escape_functions = expand_escape_spec($escape_spec);
sub expand_escape_spec {
  my $escape_spec = shift;
  
  if ( ref($escape_spec) eq 'CODE' ) {
    return $escape_spec;
  } elsif ( ref($escape_spec) eq 'ARRAY' ) {
    return map { expand_escape_spec($_) } @$escape_spec;
  } elsif ( ! ref($escape_spec) ) {
    return map { expand_escape_spec($_) }
      map { $Escapes{$_} or croak "unsupported escape specification '$_'" }
        split(/\s+/, $escape_spec);
  } else {
    croak "unsupported escape specification '$escape_spec'";
  }
}

# $escaped = escape($escape_spec, $value); 
# @escaped = escape($escape_spec, @values);
sub escape ($@) {
  my ($escape_spec, @values) = @_;
  
  croak "escape called with multiple values but in scalar context"
      if ($#values > 0 && ! wantarray);
  
  my @escapes = expand_escape_spec($escape_spec);
  
  my ($value, $escaper);
  foreach $value ( @values ) {
    foreach $escaper ( @escapes ) {
      $value = &$escaper( $value );
    }
  }
  
  return wantarray ? @values : $values[0];
}

### Double Quoting

# $with_surrounding_quotes = quote( $string_value );
sub quote ($) { '"' . $_[0] . '"' }

# $remove_surrounding_quotes = quote( $string_value );
sub unquote ($) { local $_ = $_[0]; s/\A\"(.*)\"\Z/$1/; $_; }

# $word_or_phrase_with_surrounding_quotes = quote( $string_value );
sub quote_non_words ($) {
  ( ! length $_[0] or $_[0] =~ /[^\w\_\-\/\.\:\#]/ ) ? '"'.$_[0].'"' : $_[0]
}

### Backslash Escaping

use vars qw( %Printable %Unprintable );
%Printable = ( ( map { chr($_), unpack('H2', chr($_)) } (0..255) ),
	      "\\"=>'\\', "\r"=>'r', "\n"=>'n', "\t"=>'t', "\""=>'"' );
%Unprintable = ( reverse %Printable );

# $special_characters_escaped = printable( $source_string );
sub printable ($) {
  local $_ = ( defined $_[0] ? $_[0] : '' );
  s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Printable{$1}/g;
  return $_;
}

# $original_string = unprintable( $special_characters_escaped );
sub unprintable ($) {
  local $_ = ( defined $_[0] ? $_[0] : '' );
  s/((?:\A|\G|[^\\]))\\([rRnNtT\"\\]|[\da-fA-F]{2})/$1.$Unprintable{lc($2)}/ge;
  return $_;
}

# quoted_and_escaped = qprintable( $source_string );
sub qprintable ($) { quote_non_words printable $_[0] }

# $original_string = unqprintable( quoted_and_escaped );
sub unqprintable ($) { unprintable unquote $_[0] }

1;

=pod

=head1 NAME

String::Escape - Registry of string functions, including backslash escapes


=head1 SYNOPSIS

C<use String::Escape qw( printable unprintable );>

C<$output = printable($value);>

C<$value = unprintable($input);>

C<use String::Escape qw( escape );>

C<$escape_name = $use_quotes ? 'qprintable' : 'printable';> 

C<@escaped = escape($escape_name, @values);>


=head1 DESCRIPTION

This module provides a flexible calling interface to some frequently-performed string conversion functions, including applying and removing C/Unix-style backslash escapes. For example, to inspect the line feeds and high-bit characters in a file you could use String::Escape's printable function:

    > perl -MString::Escape=printable -n -e 'print printable($_)."\n"' < ~/.cshrc
    unset auto-logout\t\t# minimal shell setup\n

The escape() function provides for dynamic selection of operations by using a package hash variable to map escape specification strings to the functions which implement them. The lookup imposes a bit of a performance penalty, but allows for some useful late-binding behaviour. Compound specifications (ex. 'quoted uppercase') are expanded to a list of functions to be applied in order. (Other modules may also register their functions here for later general use.)


=head1 REFERENCE

=head2 Escaping And Unescaping Functions

Each of these functions takes a single simple scalar argument and 
returns its escaped (or unescaped) equivalent.

=over 4

=item quote($value) : $escaped

Add double quote characters to each end of the string.

=item quote_non_words($value) : $escaped

As above, but only quotes empty, punctuated, and multiword values.

=item unquote($value) : $escaped

If the string both begins and ends with double quote characters, they are removed, otherwise the string is returned unchanged.

=item printable($value) : $escaped

=item unprintable($value) : $escaped

These functions convert return, newline, tab, backslash and unprintable 
characters to their backslash-escaped equivalents and back again.

=item qprintable($value) : $escaped

=item unqprintable($value) : $escaped

The qprintable function applies printable escaping and then wraps the results 
with quote_non_words, while unqprintable applies  unquote and then unprintable. 
(Note that this is I<not> MIME quoted-printable encoding.)

=back

=head2 Escape By-Name

These functions provide for the registration of string-escape specification 
names and corresponding functions, and then allow the invocation of one or 
several of these functions on one or several source string values.

=over 4

=item escape($escapes, $value) : $escaped_value

=item escape($escapes, @values) : @escaped_values

Returns an altered copy of the provided values by looking up the escapes string in a registry of string-modification functions.

If called in a scalar context, operates on the single value passed in; if 
called in a list contact, operates identically on each of the provided values. 

Valid escape specifications are:

=over 4

=item one of the keys defined in %Escapes

The coresponding specification will be looked up and used.

=item a sequence of names separated by whitespace,

Each name will be looked up, and each of the associated functions will be applied successively, from left to right.

=item a reference to a function

The provided function will be called on with each value in turn.

=item a reference to an array

Each item in the array will be expanded as provided above.

=back

A fatal error will be generated if you pass an unsupported escape specification, or if the function is called with multiple values in a scalar context. 

=item String::Escape::names() : @defined_escapes

Returns a list of defined escape specification strings.

=item String::Escape::add( $escape_name, \&escape_function );

Add a new escape specification and corresponding function.

=item %Escapes : $name, $operation, ...

By default, the %Escapes hash is initialized to contain the following mappings:

=over 4

=item quote, unquote, or quote_non_words

=item printable, unprintable, qprintable, or unqprintable, 

Run the above-described functions of the same names.  

=item uppercase, lowercase, or initialcase

Alters the case of letters in the string to upper or lower case, or for initialcase, sets the first letter to upper case and all others to lower.

=item none

Return an unchanged copy of the original value.

=back

=back


=head1 EXAMPLES

C<print printable( "\tNow is the time\nfor all good folks\n" );>

C<I<\tNow is the time\nfor all good folks\n>>

C<print escape('qprintable', "\tNow is the time\nfor all good folks\n" );>

C<I<"\tNow is the time\nfor all good folks\n">>

C<print escape('uppercase qprintable', "\tNow is the time\nfor all good folks\n" );>

C<I<"\tNOW IS THE TIME\nFOR ALL GOOD FOLKS\n">>

C<print join '--', escape('printable', "\tNow is the time\n", "for all good folks\n" );>

C<I<\tNow is the time\n--for all good folks\n>>


=head1 PREREQUISITES AND INSTALLATION

This package should run on any standard Perl 5 installation.

You may retrieve this package from the below URL:
  http://www.evoscript.com/dist/String-Escape-1998.0919.tar.gz

To install this package, download and unpack the distribution archive, then:

=over 4

=item * C<perl Makefile.PL>

=item * C<make test>

=item * C<make install>

=item * C<perldoc String::Escape>

=back


=head1 STATUS AND SUPPORT

This release of String::Escape is intended for public review and feedback. 
It has been tested in several environments and no major problems have been 
discovered, but it should be considered "alpha" pending that feedback.

  Name            DSLI  Description
  --------------  ----  ---------------------------------------------
  String::
  ::Escape        adpf  Escape by-name registry and useful functions

Further information and support for this module is available at E<lt>www.evoscript.comE<gt>.

Please report bugs or other problems to E<lt>bugs@evoscript.comE<gt>.


=head1 AUTHORS AND COPYRIGHT

Copyright 1997, 1998 Evolution Online Systems, Inc. E<lt>www.evolution.comE<gt>

You may use this software for free under the terms of the Artistic License. 

Contributors: 
M. Simon Cavalletto E<lt>simonm@evolution.comE<gt>,
Jeremy G. Bishop E<lt>jeremy@evolution.comE<gt>

=cut
