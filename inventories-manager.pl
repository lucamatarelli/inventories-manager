use strict;
use warnings;
use utf8;

use Storable;

if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
} elsif ($^O eq "linux") {
    binmode STDOUT, ":encoding(UTF-8)";
}

my @inventories_paths = glob "./inventories/*";

if (!@inventories_paths) {
    print "Aucun inventaire disponible\nSouhaitez-vous en créer un ? (o/n) ";
    my $input = <STDIN>;
    while ($input !~ /^o\n|n\n$/i) {
        print "Choix invalide. Souhaitez-vous créer votre premier inventaire ? (o/n) ";
        $input = <STDIN>;
    }
} else {
    print "Inventaires disponibles :\n";
}
