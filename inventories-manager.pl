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
    binmode STDIN, ":encoding(UTF-8)";
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

sub display_main_menu {
    print "\nQue souhaitez-vous faire ?\n";
    print "1. Créer un nouvel inventaire\n2. Ouvrir un inventaire\n3. Quitter le gestionnaire\n\n";
    print "Entrez le numéro de l'action à effectuer : ";
    my $option_choice_nb = input_check(qr/^[123]$/, "Veuillez entrer un numéro d'option valide : ");
    return $option_choice_nb;
}

sub create_inventory {
    print "\nNommez votre nouvel inventaire : ";
    my $new_inventory_name = input_check(qr/^[\p{L}\d -]+$/, "Nom d'inventaire non valide. Réessayez avec un format valide : ");

    print "\nEntrez les noms des macro-catégories que contiendra votre inventaire.\n(Entrez \"/\" une fois toutes vos catégories inscrites)\n";
    my $macrocategory_number = 1;
    my @macrocategories;
    print "Catégorie 1 : ";
    my $macrocategory_name = input_check(qr/^[^\/]+$/, "Vous devez entrer au moins une catégorie !\nCatégorie 1 : ");
    while ($macrocategory_name ne "/") {
        push @macrocategories, $macrocategory_name;
        print "Catégorie " . ++$macrocategory_number . " : ";
        $macrocategory_name = input_check(qr/^[^\n]+$/, "Catégorie " . $macrocategory_number . " : ");
    }
    
    my %new_inventory = new_inventory(@macrocategories);
    print "\nNouvel inventaire créé !\n\n";
    sleep 2;
    return (\%new_inventory, $new_inventory_name);
}

sub manage_inventory {
    my ($inventory_ref, $inventory_name) = @_;
    my $curr_category_ref = $inventory_ref;
    while (1) {
        my $action_choice = display_inventory_options($curr_category_ref, $inventory_name);
        my $action_result = do_action($action_choice, $curr_category_ref);
        if (ref $action_result eq "HASH") {
            $curr_category_ref = $action_result;
        } else {
            last if $action_result eq "EXIT";
        }
    }
}


{
my @subcategories_depth;

sub display_inventory_options {
    my ($curr_category_ref, $inventory_name) = @_;

    my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref)};
    my @curr_items = @{get_curr_items_ref($curr_category_ref)};

    my $option_nb = 0;
    my %valid_options;

    print "\nNiveau courant dans l'inventaire \"" . $inventory_name . "\" :\n\n";
    print category_to_string($curr_category_ref);
    print "\nActions :\n";
    if (scalar @curr_subcategories != 0) {
        print ++$option_nb . ". Aller dans une catégorie\n";
        $valid_options{$option_nb} = "go_to";
    }
    if (scalar @subcategories_depth != 0) {
        print ++$option_nb . ". Remonter d'une catégorie\n";
        $valid_options{$option_nb} = "go_up";
    }
    print ++$option_nb . ". Ajouter une catégorie\n";
    $valid_options{$option_nb} = "add_cat";
    if (scalar @curr_subcategories != 0) {
        print ++$option_nb . ". Renommer une catégorie\n";
        $valid_options{$option_nb} = "ren_cat";
        print ++$option_nb . ". Déplacer une catégorie\n";
        $valid_options{$option_nb} = "mv_cat";
        print ++$option_nb . ". Supprimer une catégorie\n";
        $valid_options{$option_nb} = "rm_cat";
    }
    if (scalar @subcategories_depth != 0) {
        print ++$option_nb . ". Ajouter un item\n";
        $valid_options{$option_nb} = "add_it";
    }
    if (scalar @curr_items != 0) {
        print ++$option_nb . ". Renommer un item\n";
        $valid_options{$option_nb} = "ren_it";
        print ++$option_nb . ". Déplacer un item\n";
        $valid_options{$option_nb} = "mv_it";
        print ++$option_nb . ". Supprimer un item\n";
        $valid_options{$option_nb} = "rm_it";
    }
    print ++$option_nb . ". Enregistrer l'inventaire et quitter\n";
    $valid_options{$option_nb} = "quit_save";
    print ++$option_nb . ". Quitter sans enregistrer\n\n";
    $valid_options{$option_nb} = "quit_nosave";

    print "Entrez le numéro de l'action à effectuer : ";
    my $valid_options_disjunction = join "|", keys %valid_options;
    my $option_choice_nb = input_check(qr/^($valid_options_disjunction)$/, "Veuillez entrer un numéro d'option valide : ");
    return $valid_options{$option_choice_nb};
}

sub do_action {
    my ($action, $curr_category_ref) = @_;

    my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref)};
    my $curr_subcategories_disjunction = join "|", @curr_subcategories;
    my @curr_items = @{get_curr_items_ref($curr_category_ref)};
    my $curr_items_disjunction = join "|", @curr_items;

    if ($action eq "go_to") {
        push @subcategories_depth, $curr_category_ref;
        print "Déplacement vers quelle catégorie ? ";
        my $new_curr_category = input_check(qr/^($curr_subcategories_disjunction)$/, "Veuillez entrer un nom de catégorie valide : ");
        $curr_category_ref = $curr_category_ref->{$new_curr_category};        
    } elsif ($action eq "go_up") {
        $curr_category_ref = pop @subcategories_depth;
    } elsif ($action eq "add_cat") {
        print "Nommez votre nouvelle catégorie : ";
        my $new_category_name = <STDIN>;
        chomp $new_category_name;
        add_category($curr_category_ref, $new_category_name);
    } elsif ($action eq "ren_cat") {
        print "Quelle catégorie souhaitez-vous renommer ? ";
        my $category_to_rename = input_check(qr/^($curr_subcategories_disjunction)$/, "Veuillez entrer un nom de catégorie valide : ");
        print "Indiquez le nouveau nom de [" . $category_to_rename . "] : "; 
        my $category_new_name = <STDIN>;
        chomp $category_new_name;
        rename_category($curr_category_ref, $category_to_rename, $category_new_name);
    } elsif ($action eq "mv_cat") {
        
    } elsif ($action eq "rm_cat") {
        print "Quelle catégorie souhaitez-vous supprimer ? ";
        my $category_to_remove = input_check(qr/^($curr_subcategories_disjunction)$/, "Veuillez entrer un nom de catégorie valide : ");
        remove_category($curr_category_ref, $category_to_remove);
    } elsif ($action eq "add_it") {
        print "Nouvel item : ";
        my $new_item = <STDIN>;
        chomp $new_item;
        add_item($curr_category_ref, $new_item);
    } elsif ($action eq "ren_it") {
        print "Quel item souhaitez-vous renommer ? ";
        my $item_to_rename = input_check(qr/^($curr_items_disjunction)$/, "Veuillez entrer un nom d'item valide : ");
        print "Indiquez le nouveau nom de \"" . $item_to_rename . "\" : "; 
        my $item_new_name = <STDIN>;
        chomp $item_new_name;
        rename_item($curr_category_ref, $item_to_rename, $item_new_name);
    } elsif ($action eq "mv_it") {
        
    } elsif ($action eq "rm_it") {
        print "Quel item souhaitez-vous supprimer ? ";
        my $item_to_remove = input_check(qr/^($curr_items_disjunction)$/, "Veuillez entrer un nom d'item valide : ");
        remove_item($curr_category_ref, $item_to_remove);
    } elsif ($action eq "quit_save") {
        return "EXIT";
    } elsif ($action eq "quit_nosave") {
        return "EXIT";
    }
    return $curr_category_ref;
}
}


my @inventories_paths = glob "./inventories/*";

if (scalar @inventories_paths == 0) {
    print "Aucun inventaire disponible.\nSouhaitez-vous en créer un ? (o/n) ";    
    my $first_inventory_confirmation = input_check(qr/^[on]$/i, "Choix invalide. Souhaitez-vous créer votre premier inventaire ? (o/n) ");
    if ($first_inventory_confirmation =~ /^o$/i) {
        my ($first_inventory_ref, $first_inventory_name) = create_inventory();       
        manage_inventory($first_inventory_ref, $first_inventory_name);
        my $main_menu_action = display_main_menu();
    }
} else {
    print "Inventaires disponibles :\n";
}