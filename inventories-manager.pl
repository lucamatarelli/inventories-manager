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
    print "\nNiveau courant dans l'inventaire \"" . $inventory_name . "\" :\n\n";
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
    my ($option_number, $curr_category_ref) = @_;

    my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref)};
    my $curr_subcategories_disjunction = join "|", @curr_subcategories;
    my @curr_items = @{get_curr_items_ref($curr_category_ref)};
    my $curr_items_disjunction = join "|", @curr_items;

    if ($option_number eq "1") {
        print "Déplacement vers quelle catégorie ? ";
        my $new_category_ref = input_check(qr/^($curr_subcategories_disjunction)$/, "Veuillez entrer un nom de catégorie valide : ");
        $curr_category_ref = $curr_category_ref->{$new_category_ref};        
     } elsif ($option_number eq "2") {

    } elsif ($option_number eq "3") {
        print "Nommez votre nouvelle catégorie : ";
        my $new_category_name = <STDIN>;
        chomp $new_category_name;
        add_category($curr_category_ref, $new_category_name);
    } elsif ($option_number eq "4") {
        print "Quelle catégorie souhaitez-vous renommer ? ";
        my $category_to_rename = input_check(qr/^($curr_subcategories_disjunction)$/, "Veuillez entrer un nom de catégorie valide : ");
        print "Indiquez le nouveau nom de [" . $category_to_rename . "] : "; 
        my $category_new_name = <STDIN>;
        chomp $category_new_name;
        rename_category($curr_category_ref, $category_to_rename, $category_new_name);
    } elsif ($option_number eq "5") {
        
    } elsif ($option_number eq "6") {
        print "Quelle catégorie souhaitez-vous supprimer ? ";
        my $category_to_remove = input_check(qr/^($curr_subcategories_disjunction)$/, "Veuillez entrer un nom de catégorie valide : ");
        remove_category($curr_category_ref, $category_to_remove);
    } elsif ($option_number eq "7") {
        print "Nouvel item : ";
        my $new_item = <STDIN>;
        chomp $new_item;
        add_item($curr_category_ref, $new_item);
    } elsif ($option_number eq "8") {
        print "Quel item souhaitez-vous renommer ? ";
        my $item_to_rename = input_check(qr/^($curr_items_disjunction)$/, "Veuillez entrer un nom d'item valide : ");
        print "Indiquez le nouveau nom de \"" . $item_to_rename . "\" : "; 
        my $item_new_name = <STDIN>;
        chomp $item_new_name;
        rename_item($curr_category_ref, $item_to_rename, $item_new_name);
    } elsif ($option_number eq "9") {
        
    } elsif ($option_number eq "10") {
        print "Quel item souhaitez-vous supprimer ? ";
        my $item_to_remove = input_check(qr/^($curr_items_disjunction)$/, "Veuillez entrer un nom d'item valide : ");
        remove_item($curr_category_ref, $item_to_remove);
    } elsif ($option_number eq "11") {
        return "EXIT";
    } elsif ($option_number eq "12") {
        return "EXIT";        
    }
    return $curr_category_ref;
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

        my $curr_category_ref = \%new_inventory;
        while (1) {
            my $choice = display_inventory_options($curr_category_ref, $new_inventory_name);
            my $action_result = do_action($choice, $curr_category_ref);
            if (ref $action_result eq "HASH") {
                $curr_category_ref = $action_result;
            } else {
                last if $action_result eq "EXIT";
            }
        }
    }
} else {
    print "Inventaires disponibles :\n";
}