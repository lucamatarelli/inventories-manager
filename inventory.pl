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
    print "Aucun inventaire disponible\nVoulez-vous en créer un ? (o/n) ";
    my $input = <STDIN>;
} else {
    print "Inventaires disponibles :\n";
}
