use strict;
use warnings;
use utf8;

use Storable;
use Data::Dump;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use lib dirname(abs_path($0));

use Inventory;

if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
} elsif ($^O eq "linux") {
    binmode STDOUT, ":encoding(UTF-8)";
}

my @inventories_paths = glob "./inventories/*";

# if (!@inventories_paths) {
#     print "Aucun inventaire disponible\nSouhaitez-vous en créer un ? (o/n) ";
#     my $input = <STDIN>;
#     while ($input !~ /^o\n|n\n$/i) {
#         print "Choix invalide. Souhaitez-vous créer votre premier inventaire ? (o/n) ";
#         $input = <STDIN>;
#     }
# } else {
#     print "Inventaires disponibles :\n";
# }

my %ninv = Inventory::create_inventory("chaussures", "pulls", "chemises");
dd %ninv;
Inventory::add_item(\%ninv, "chemises", "Boggi Milano bleu vichy Button down");
Inventory::add_item(\%ninv, "pulls", "Chevignon cachemire marron");
Inventory::add_item(\%ninv, "pulls", "Benjamin Jezequel rose gaufré");
Inventory::add_category(\%ninv, "jeans");
dd %ninv;