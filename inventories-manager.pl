use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin";
use File::Copy;
use List::Util qw(any);
use Storable;

use Inventory;

if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
    binmode STDIN, ":encoding(CP-850)";
} elsif ($^O eq "linux") {
    binmode STDOUT, ":encoding(UTF-8)";
    binmode STDIN, ":encoding(UTF-8)";
}

sub main_loop_menu {
    my $action_choice = "";
    while ($action_choice ne "EXIT") {
        my @inventories = get_inventories();
        my $inventories_disjunction = join "|", @inventories;

        if (scalar @inventories == 0) {
            print "\nAucun inventaire disponible.\n";
        } else {
            print "\nInventaires disponibles :\n";
            print "=> " . $_ . "\n" for (@inventories);
        }

        my $option_nb = 0;
        my %valid_options;

        print "\nQue souhaitez-vous faire ?\n";

        print ++$option_nb . ". Créer un nouvel inventaire\n";
        $valid_options{$option_nb} = "add_inv";
        if (scalar @inventories != 0) {
            print ++$option_nb . ". Ouvrir un inventaire\n";
            $valid_options{$option_nb} = "open_inv";
            print ++$option_nb . ". Renommer un inventaire\n";
            $valid_options{$option_nb} = "ren_inv";
            print ++$option_nb . ". Supprimer un inventaire\n";
            $valid_options{$option_nb} = "rm_inv";
        }
        print ++$option_nb . ". Quitter le gestionnaire\n\n";
        $valid_options{$option_nb} = "EXIT";

        print "Entrez le numéro de l'action à effectuer : ";
        my $option_choice_nb = scalar @inventories != 0 ?
            input_check(qr/^[12345]$/, "Veuillez entrer un numéro d'action valide : ") :
            input_check(qr/^[12]$/, "Veuillez entrer un numéro d'action valide : ");
        $action_choice = $valid_options{$option_choice_nb};

        if ($action_choice eq "add_inv") {
            my ($new_inventory_ref, $new_inventory_name) = create_inventory();
            manage_inventory($new_inventory_ref, $new_inventory_name);
        } elsif ($action_choice eq "open_inv") {
                print "\nQuel inventaire souhaitez-vous ouvrir ? ";
                my $inventory_to_open_name = input_check(qr/^($inventories_disjunction)$/, "Veuillez saisir un nom d'inventaire valide : ");
                my $inventory_to_open_ref = retrieve "$FindBin::Bin/inventories/$inventory_to_open_name";
                manage_inventory($inventory_to_open_ref, $inventory_to_open_name);
        } elsif ($action_choice eq "ren_inv") {
            print "\nQuel inventaire souhaitez-vous renommer ? ";
            my $inventory_to_rename = input_check(qr/^($inventories_disjunction)$/, "Veuillez saisir un nom d'inventaire valide : ");

            print "Indiquez le nouveau nom de \"" . $inventory_to_rename . "\" : ";
            my $inventory_new_name = "";
            while (1) {
                $inventory_new_name = input_check(qr/^[\p{L}\d_-]+$/, "Format non valide. Indiquez le nouveau nom de \"" . $inventory_to_rename . "\" : ");
                last if (not any {$_ eq $inventory_new_name} @inventories);
                print "Un inventaire porte déjà le nom de \"$inventory_new_name\".\nVeuillez choisir un nom différent : ";
            }

            move "$FindBin::Bin/inventories/$inventory_to_rename", "$FindBin::Bin/inventories/$inventory_new_name";
        } elsif ($action_choice eq "rm_inv") {
            print "\nQuel inventaire souhaitez-vous supprimer ? ";
            my $inventory_to_remove = input_check(qr/^($inventories_disjunction)$/, "Veuillez saisir un nom d'inventaire valide : ");

            print "\nCette opération supprimera irréversiblement l'inventaire \"$inventory_to_remove\" et son contenu.\n";
            print "Êtes-vous sûr de vouloir continuer (o/n) ? ";
            my $rm_confirm = input_check(qr/^[on]$/i, "Choix non valide. Êtes-vous sûr de vouloir supprimer \"$inventory_to_remove\" (o/n) ? ");

            unlink "$FindBin::Bin/inventories/$inventory_to_remove" if ($rm_confirm =~ /^[oO]$/);            
        }
    }
}

sub create_inventory {
    print "\nNommez votre nouvel inventaire : ";
    my @inventories = get_inventories();
    my $new_inventory_name = "";
    while (1) {
        $new_inventory_name = input_check(qr/^[\p{L}\d_-]+$/, "Format non valide. Nommez votre nouvel inventaire : ");
        last if (not any {$_ eq $new_inventory_name} @inventories);
        print "Un inventaire porte déjà le nom de \"$new_inventory_name\".\nVeuillez choisir un nom différent : ";
    }

    print "\nEntrez les noms des macro-catégories que contiendra votre inventaire.\n(Entrez \"/\" une fois toutes vos catégories inscrites)\n";
    my $macrocategory_number = 1;
    my @macrocategories;
    print "Catégorie 1 : ";
    my $macrocategory_name = input_check(qr/^[^\s\/](.*[^\s])*$/, "Vous devez entrer au moins une catégorie valide !\nCatégorie 1 : ");
    while ($macrocategory_name ne "/") {
        push @macrocategories, $macrocategory_name;
        print "Catégorie " . ++$macrocategory_number . " : ";
        $macrocategory_name = input_check(qr/^[^\s](.*[^\s])*$/, "Format non valide. Catégorie " . $macrocategory_number . " : ");
    }
    
    my %new_inventory = new_inventory(@macrocategories);
    print "\nNouvel inventaire créé !\n\n";
    sleep 2;
    return (\%new_inventory, $new_inventory_name);
}

sub manage_inventory {
    my ($inventory_ref, $inventory_name) = @_;
    my $curr_category_ref = $inventory_ref;
    my $action_result = "";
    while ($action_result !~ /^EXIT/) {
        my $action_choice = display_inventory_options($curr_category_ref, $inventory_name);
        $action_result = do_action($action_choice, $curr_category_ref);
        if (ref $action_result eq "HASH") {
            $curr_category_ref = $action_result;
        } else {
            store $inventory_ref, "$FindBin::Bin/inventories/$inventory_name" if $action_result =~ /-SV$/;
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
        my $option_choice_nb = input_check(qr/^($valid_options_disjunction)$/, "Veuillez entrer un numéro d'action valide : ");
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
            my $new_category_name = "";
            while (1) {
                $new_category_name = input_check(qr/^[^\s](.*[^\s])*$/, "Format non valide. Nommez votre nouvelle catégorie : ");
                last if (not any {$_ eq $new_category_name} @curr_subcategories);
                print "Une catégorie porte déjà le nom de \"$new_category_name\".\nVeuillez choisir un nom différent : ";
            }
            add_category($curr_category_ref, $new_category_name);
        } elsif ($action eq "ren_cat") {
            print "Quelle catégorie souhaitez-vous renommer ? ";
            my $category_to_rename = input_check(qr/^($curr_subcategories_disjunction)$/, "Veuillez entrer un nom de catégorie valide : ");
            print "Indiquez le nouveau nom de [" . $category_to_rename . "] : ";
            my $category_new_name = "";
            while (1) {
                $category_new_name = input_check(qr/^[^\s](.*[^\s])*$/, "Format non valide. Nommez votre nouvelle catégorie : ");
                last if (not any {$_ eq $category_new_name} @curr_subcategories);
                print "Une catégorie porte déjà le nom de \"$category_new_name\".\nVeuillez choisir un nom différent : ";
            }
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
            return "EXIT-SV";
        } elsif ($action eq "quit_nosave") {
            return "EXIT";
        }
        return $curr_category_ref;
    }
}

sub get_inventories {
    my @inventories_paths = glob "$FindBin::Bin/inventories/*";
    my @inventories = grep {$_ =~ s/.+\/(.+)/$1/} @inventories_paths;
    return @inventories;

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


main_loop_menu();