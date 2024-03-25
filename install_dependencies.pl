# install_dependencies.pl
# Script to install potentially missing external Perl modules that are required by the program.

use strict;
use warnings;
use utf8;

# Encoding layer for properly displayed CLI interactions
if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
    binmode STDIN, ":encoding(CP-850)";
} else {
    binmode STDOUT, ":encoding(UTF-8)";
    binmode STDIN, ":encoding(UTF-8)";
}

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
    print "Les modules suivants ne sont pas installés : $dependencies\n";
    print "\nNB : le module GraphViz2 nécessite l'installation préalable du logiciel de visualisation graphique GraphViz (ainsi que son ajout au PATH) : https://www.graphviz.org/download/.\n\n";
    print "Voulez-vous installer les modules manquants ? (o/n) ";

    my $user_choice = <STDIN>;
    chomp $user_choice;
    print "\n";

    if ($user_choice eq "o") {
        my $installation_status = system("cpanm $dependencies");
        print "\n";
        if ($installation_status == 0) {
            print "Installation des modules réussie.\n";
            sleep 1;
            exit 0;
        } else {
            print "Erreur lors de l'installation des modules.\n";
            exit 1;
        }
    } else {
        print "Les modules suivants sont requis pour exécuter le script : $dependencies\n";
        print "Veillez à les installer avant de relancer le script.\n";
        exit 1;
    }
}