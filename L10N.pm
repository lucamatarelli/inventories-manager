package L10N;
use base qw(Locale::Maketext);

use strict;
use warnings;
use utf8;
use feature qw(say);

# This utility method is used to print localized strings
# PARAMS : string to localize (string)
sub say_localized {
    my ($language_handle, $string_to_localize, @parameters) = @_;
    say $language_handle->maketext($string_to_localize, @parameters);
}

1;