# install_dependencies.pl
# Script to install potentially missing external Perl modules that are required by the program.

use strict;
use warnings;
use utf8;

my @necessary_modules = qw(GraphViz2);

my @missing_modules = get_missing_modules();
if (scalar @missing_modules > 0) {
    return install_dependencies(@missing_modules);
}

sub get_missing_modules {
    my @missing_modules;
    foreach my $module (@necessary_modules) {
        if (!eval "require $module") {
            push @missing_modules, $module;
        }
    }
    return @missing_modules;
}

sub install_dependencies {
    my @missing_modules = @_;

    my $dependencies = join " ", @missing_modules;
    print "The following modules are not installed: $dependencies\n";
    print "Do you want to install them? (y/n) ";

    my $user_choice = <STDIN>;
    chomp $user_choice;
    if ($user_choice eq "y") {
        system("cpanm $dependencies");
        exit 0;
    } else {
        print "The following modules are required to run the script: $dependencies\n";
        print "Please install them and run the script again.\n";
        exit 1;
    }
}