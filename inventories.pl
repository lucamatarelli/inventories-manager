# inventory_manager.pl
# This main script provides a simple inventory management system through CLI.
# Users can create, open, rename, and delete inventories, manage categories,
# and perform various actions within the inventory system.

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin";
use Encode qw(encode);
use File::Copy;
use List::Util qw(any);
use Storable;
use Term::ANSIColor;

use InventoryManipulation;
use Utilities;

# Encoding layer for proper CLI interactions
if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
    binmode STDIN, ":encoding(CP-850)";
}

# Main user interface loop for handling general actions
sub main_loop_menu {
    my $chosen_action = "";
    while ($chosen_action ne "EXIT") {        
        my @available_inventories = get_inventories();

        display_inventories(@available_inventories);
        my $valid_menu_options_ref = display_main_menu(@available_inventories);
        $chosen_action = get_user_choice($valid_menu_options_ref);
        perform_main_action($chosen_action, @available_inventories);
    }
}

# Display available inventories
sub display_inventories {
    my (@inventories) = @_;

    print "_" x 100 . "\n";
    if (scalar @inventories == 0) {
        print "\nAucun inventaire disponible.\n";
    } else {
        print "\nInventaires disponibles :\n";
        print "-> " . colored($_ . "\n", "magenta") for (@inventories);
    }
}

# Display main menu options
sub display_main_menu {
    my (@inventories) = @_;

    my $option_nb = 0;
    my %valid_options;

    print "\nQue souhaitez-vous faire ?\n";

    print ++$option_nb . ". Ajouter un inventaire\n";
    $valid_options{$option_nb} = "add_inv";
    if (scalar @inventories != 0) {
        print ++$option_nb . ". Ouvrir un inventaire\n";
        $valid_options{$option_nb} = "open_inv";
        print ++$option_nb . ". Renommer un inventaire\n";
        $valid_options{$option_nb} = "ren_inv";
        print ++$option_nb . ". Supprimer un inventaire\n";
        $valid_options{$option_nb} = "rm_inv";
        print ++$option_nb . ". Visualiser l'inventaire\n";
        $valid_options{$option_nb} = "viz_inv";        
    }
    print ++$option_nb . ". Quitter le gestionnaire\n\n";
    $valid_options{$option_nb} = "EXIT";

    return \%valid_options;
}

# Ask user input for action
sub get_user_choice {
    my ($valid_options_ref) = @_;
    my %valid_options = %$valid_options_ref;

    my $options_numbers = join "", 1..keys %valid_options;
    my $option_choice_nb = input_check("> Entrez le numéro de l'action à effectuer : ",
                                        qr/^[$options_numbers]$/,
                                        "> Veuillez entrer un numéro d'action valide : ");
    return $valid_options{$option_choice_nb};
}

# Perform main menu action based on user choice
sub perform_main_action {
    my ($chosen_action, @inventories) = @_;    
    my $inventories_disjunction = join "|", @inventories;

    if ($chosen_action eq "add_inv") {
        # Add a new inventory
        my ($new_inventory_ref, $new_inventory_name) = add_inventory();
        manage_inventory($new_inventory_ref, $new_inventory_name);
    } elsif ($chosen_action eq "open_inv") {
        # Open an existing inventory
        my $inventory_to_open_name = input_check("\n> Entrez le nom de l'inventaire à ouvrir : ",
                                                    qr/^($inventories_disjunction)$/,
                                                    "> Veuillez saisir un nom d'inventaire valide : ");
        my $inventory_to_open_ref = retrieve encode("CP-1252", "$FindBin::Bin/inventories/$inventory_to_open_name");
        manage_inventory($inventory_to_open_ref, $inventory_to_open_name);
    } elsif ($chosen_action eq "ren_inv") {
        # Rename an existing inventory
        my $inventory_to_rename = input_check("\n> Entrez le nom de l'inventaire à renommer : ",
                                                qr/^($inventories_disjunction)$/,
                                                "> Veuillez saisir un nom d'inventaire valide : ");

        # Ensure that the new inventory name is valid and not already in use in the current inventories
        my $inventory_new_name = "";
        while (1) {
            $inventory_new_name = input_check("> Indiquez le nouveau nom de {<MAGENTA_BEGIN>$inventory_to_rename<MAGENTA_END>} : ",
                                                qr/^[\p{L}\d_-]+$/,
                                                "> Format non valide. Indiquez le nouveau nom de {<MAGENTA_BEGIN>$inventory_to_rename<MAGENTA_END>} : ");
            last if (not any {$_ eq $inventory_new_name} @inventories);
            print colorize("<RED_BEGIN>Un inventaire porte déjà le nom de \"<MAGENTA_BEGIN>$inventory_new_name<MAGENTA_END>\". Veuillez choisir un nom différent.\n<RED_END>");
        }

        move encode("CP-1252", "$FindBin::Bin/inventories/$inventory_to_rename"), encode("CP-1252", "$FindBin::Bin/inventories/$inventory_new_name");
    } elsif ($chosen_action eq "rm_inv") {
        # Remove an existing inventory
        my $inventory_to_remove = input_check("\n> Entrez le nom de l'inventaire à supprimer : ",
                                                qr/^($inventories_disjunction)$/,
                                                "> Veuillez saisir un nom d'inventaire valide : ");

        my $rm_confirm = input_check(
            "\nCette opération supprimera irréversiblement l'inventaire {<MAGENTA_BEGIN>"
                . $inventory_to_remove
                . "<MAGENTA_END>} et son contenu.\n"
                . "> Êtes-vous sûr de vouloir continuer (o/n) ? ",
            qr/^[on]$/i,
            "> Choix non valide. Êtes-vous sûr de vouloir supprimer {<MAGENTA_BEGIN>$inventory_to_remove<MAGENTA_END>} (o/n) ? ");

        unlink encode("CP-1252", "$FindBin::Bin/inventories/$inventory_to_remove") if ($rm_confirm =~ /^[oO]$/);            
    } elsif ($chosen_action eq "viz_inv") {
        # Save a graph representation of a whole inventory as an external PNG image
        my $inventory_to_visualize_name = input_check("\n> Entrez le nom de l'inventaire à visualiser : ",
                                                        qr/^($inventories_disjunction)$/,
                                                        "> Veuillez saisir un nom d'inventaire valide : ");
        my $inventory_to_visualize_ref = retrieve encode("CP-1252", "$FindBin::Bin/inventories/$inventory_to_visualize_name");
        visualize_inventory($inventory_to_visualize_ref, $inventory_to_visualize_name);
        
        print "\nVisualisation de l'inventaire {" . colored($inventory_to_visualize_name, "magenta") . "} générée";
        print " et accessible dans " . colored("img/$inventory_to_visualize_name.png", "magenta") . ".\n\n";
        sleep 2;
    }
}


main_loop_menu();