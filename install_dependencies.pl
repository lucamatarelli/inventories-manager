# install_dependencies.pl
# Utility preliminary script to install potentially missing external Perl modules that are required by the program.

use strict;
use warnings;
use utf8;

BEGIN {
    # Add the current directory to the @INC array to load local modules
    use Encode qw(encode);
    use FindBin qw($Bin);
    push @INC, encode("CP-1252", $FindBin::Bin);
}

# Localization module loading
use L10N;
our $lh = L10N->get_handle($ARGV[0])
    or die "Impossible to load the localization module: $!\n";
sub say_localized { L10N::say_localized($lh, @_); }

use List::Util qw(any);

# Encoding layer for properly displayed CLI interactions
if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
    binmode STDIN, ":encoding(CP-850)";
} else {
    binmode STDOUT, ":encoding(UTF-8)";
    binmode STDIN, ":encoding(UTF-8)";
}

# List of necessary Perl modules for the program to run properly
my @necessary_modules = qw(GraphViz2);
push @necessary_modules, "Win32::Locale" if $^O eq "MSWin32";

# Check if all necessary modules are installed
my @missing_modules = get_missing_modules();
if (scalar @missing_modules > 0) {
    return install_dependencies(@missing_modules);
}

# Check for all missing necessary modules
sub get_missing_modules {
    my @missing_modules;
    foreach my $module (@necessary_modules) {
        if (!eval "require $module") {
            push @missing_modules, $module;
        }
    }
    return @missing_modules;
}

# Attempt to install all missing necessary modules
sub install_dependencies {
    my @missing_modules = @_;

    my $dependencies = join ", ", @missing_modules;
    say_localized("missing_modules", $dependencies);
    say_localized("graphviz_warning") if any { $_ eq "GraphViz2" } @missing_modules;
    print $lh->maketext("install_dependencies");

    my $user_choice = <STDIN>;
    chomp $user_choice;
    print "\n";

    if ($user_choice =~ /^[oy]$/i) {
        my $installation_status = system("cpanm $dependencies");
        print "\n";
        if ($installation_status == 0) {
            say_localized("install_dependencies_success");
            sleep 1;
            exit 0;
        } else {
            say_localized("install_dependencies_error");
            exit 1;
        }
    } else {
        say_localized("install_dependencies_refusal", $dependencies);
        exit 1;
    }
}