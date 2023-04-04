use strict;
use warnings;
use utf8;

use Storable;
use FindBin;
use lib "$FindBin::Bin";

use Inventory;

if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
    binmode STDIN, ":encoding(CP-850)";
} elsif ($^O eq "linux") {
    binmode STDOUT, ":encoding(UTF-8)";
}

sub input_check {
    my ($pattern, $fail_msg) = @_;
    my $user_input = <STDIN>;
    chomp $user_input;
    while ($user_input !~ $pattern) {
        print $fail_msg;
        $user_input = <STDIN>;
        chomp $user_input;
    }
    return $user_input;
}

sub display_inventory_options {
    my ($curr_category_ref, $inventory_name) = @_;
    print "Niveau courant dans l'inventaire \"" . $inventory_name . "\" :\n\n";
    print category_to_string($curr_category_ref);
    print "\nActions :\n";
    print "1. Aller dans une catégorie\n";
    print "2. Remonter d'une catégorie\n";
    print "3. Ajouter une catégorie\n4. Renommer une catégorie\n5. Déplacer une catégorie\n6. Supprimer une catégorie\n";
    print "7. Ajouter un item\n8. Renommer un item\n9. Déplacer un item\n10. Supprimer un item\n";
    print "11. Enregistrer l'inventaire et quitter\n12. Quitter sans enregistrer\n\n";
    print "Entrez le numéro de l'action à effectuer : ";
    my $option_choice = input_check(qr/^([1-9]|10|11|12)$/, "Veuillez entrer un numéro d'option valide : ");
    return $option_choice;
}

sub do_action {

}

my @inventories_paths = glob "./inventories/*";
my $input = "";

if (scalar @inventories_paths == 0) {
    print "Aucun inventaire disponible.\nSouhaitez-vous en créer un ? (o/n) ";    
    $input = input_check(qr/^[on]$/i, "Choix invalide. Souhaitez-vous créer votre premier inventaire ? (o/n) ");
    if ($input =~ /^o$/i) {
        print "\nNommez votre nouvel inventaire : ";
        my $new_inventory_name = input_check(qr/^[\p{L}\d -]+$/, "Nom d'inventaire non valide. Réessayez avec un format valide : ");

        print "\nEntrez les noms des macro-catégories que contiendra votre inventaire.\n(Entrez \"/\" une fois toutes vos catégories inscrites)\n";
        my $macrocategory_number = 1;
        my @macrocategories;
        print "Catégorie 1 : ";
        $input = input_check(qr/^[^\/]+$/, "Vous devez entrer au moins une catégorie !\nCatégorie 1 : ");
        while ($input ne "/") {
            $macrocategory_number++;
            print "Catégorie " . $macrocategory_number . " : ";
            push @macrocategories, $input;
            $input = input_check(qr/^[^\n]+$/, "Catégorie " . $macrocategory_number . " : ");
            chomp $input;
        }
        
        my %new_inventory = new_inventory(@macrocategories);
        print "\nNouvel inventaire créé !\n\n";
        sleep 2;
        my $choice = display_inventory_options(\%new_inventory, $new_inventory_name);
    }
} else {
    print "Inventaires disponibles :\n";
}