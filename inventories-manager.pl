use strict;
use warnings;
use utf8;

use Storable;
use Data::Dump;
use FindBin;
use lib "$FindBin::Bin";

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


# Tests d'inventaire
my %inv = Inventory::new_inventory("Chaussures", "Pulls", "Chemises");
# dd %inv;
Inventory::add_category($inv{Chemises}, "Chemises formelles");
Inventory::add_item($inv{Chemises}->{"Chemises formelles"}, "Boggi Milano bleu vichy Button down");
Inventory::add_item($inv{Chemises}->{"Chemises formelles"}, "Popover denim bleu clair pini parma");
Inventory::add_item($inv{Chemises}->{"Chemises formelles"}, "Flanelle carreaux bordeaux blanche Uniqlo");
Inventory::add_item($inv{Pulls}, "Chevignon cachemire marron");
Inventory::add_item($inv{Pulls}, "Benjamin Jezequel rose gaufré");
Inventory::add_item($inv{Chaussures}, "Paraboots bi-matière");
Inventory::add_item($inv{Chaussures}, "Converse Chuck Taylor 70 moutarde");
Inventory::add_item($inv{Chaussures}, "Novesta en toile et semelle caoutchouc");
Inventory::rename_item($inv{Chaussures}, "Paraboots bi-matière", "Souliers Paraboots daim et cuir lisse");
Inventory::remove_item($inv{Chaussures}, "Novesta en toile et semelle caoutchouc");
Inventory::rename_category($inv{Chemises}, "Chemises formelles", "Chemises habillées");
# Inventory::remove_category(\%inv, "pulls");
# Inventory::remove_category($inv{Chemises}, "Chemises habillées");
# Inventory::remove_category(\%inv, "chemises");
# dd %inv;
print Inventory::category_to_string($inv{Chemises}->{"Chemises habillées"});