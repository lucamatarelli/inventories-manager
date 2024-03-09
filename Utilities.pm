# Module containing various utility routines
package Utilities;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    get_inventories
    input_check
    colorize
);

use strict;
use warnings;
use utf8;

use FindBin;
use Term::ANSIColor;
use List::Util qw(any);

# Utility routine: gather the names of all previously created inventories
# RETURNS : list of all inventories currently available in the "inventories" folder (strings)
sub get_inventories {
    mkdir "inventories" if not any {$_ eq "inventories"} glob "*";
    my @inventories_paths = glob "$FindBin::Bin/inventories/*";
    my @inventories = grep {$_ =~ s/.+\/(.+)/$1/} @inventories_paths;
    return @inventories;

}

# Utility routine: prompt message, check user input and display error message if needed
# PARAMS : a prompt message (string), 
#          a regular expression pattern to test the user input with
#          and a message to display in case of mismatch (string)
# RETURNS : the final accepted user input
sub input_check {
    my ($prompt_message, $pattern, $fail_message) = @_;
    print colorize("<CYAN_BEGIN>" . $prompt_message . "<CYAN_END>");
    my $user_input = <STDIN>;
    chomp $user_input;
    while ($user_input !~ $pattern) {
        print colorize("<RED_BEGIN>" . $fail_message . "<RED_END>");
        $user_input = <STDIN>;
        chomp $user_input;
    }
    return $user_input;
}

# Utility routine: integrate nested colors schemes
# PARAMS : a string containing schemes of <COLOR_BEGIN> and <COLOR_END>
# RETURNS : the input string with all schemes properly replaced with corresponding colors
sub colorize {
    my ($string) = @_;

    my @color_stack;
    my @strings_to_colorize = grep { $_ ne '' } split(/<[A-Z]+_(?:BEGIN|END)>/, $string);
    my $colorized_string;

    my $color_boundaries_counter = 0;
    while ($string =~ /<([A-Z]+)_(BEGIN|END)>/g) {
        if ($2 eq "BEGIN") {
            push @color_stack, $1;
        } elsif ($2 eq "END") {
            pop @color_stack;
        }
        $colorized_string .= colored($strings_to_colorize[$color_boundaries_counter], lc $color_stack[-1]);
        $color_boundaries_counter++;
        if ($color_boundaries_counter == @strings_to_colorize) {
            last;
        }
    }
    return $colorized_string;
}

1;