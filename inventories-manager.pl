# inventory_manager.pl
# This script provides a simple inventory management system.
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

# Module containing all low-level manipulation routines on inventory data structure
use Inventory;

# Encoding layer for proper CLI interactions
if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
    binmode STDIN, ":encoding(CP-850)";
}

# Main user interface loop for handling general actions
sub main_loop_menu {
    my $action_choice = "";
    while ($action_choice ne "EXIT") {
        my @inventories = get_inventories();
        my $inventories_disjunction = join "|", @inventories;

        # Display available inventories
        print "_" x 100 . "\n";
        if (scalar @inventories == 0) {
            print "\nAucun inventaire disponible.\n";
        } else {
            print "\nInventaires disponibles :\n";
            print "-> " . colored($_ . "\n", "magenta") for (@inventories);
        }

        # Display menu options
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

        # Ask user input for action
        my $option_choice_nb = scalar @inventories != 0 ?
            input_check("> Entrez le numéro de l'action à effectuer : ",
                        qr/^[12345]$/,
                        "> Veuillez entrer un numéro d'action valide : ") :
            input_check("> Entrez le numéro de l'action à effectuer : ",
                        qr/^[12]$/,
                        "> Veuillez entrer un numéro d'action valide : ");
        $action_choice = $valid_options{$option_choice_nb};

        # Perform action based on user choice
        if ($action_choice eq "add_inv") {
            # Add a new inventory
            my ($new_inventory_ref, $new_inventory_name) = create_inventory();
            manage_inventory($new_inventory_ref, $new_inventory_name);
        } elsif ($action_choice eq "open_inv") {
            # Open an existing inventory
            my $inventory_to_open_name = input_check("\n> Entrez le nom de l'inventaire à ouvrir : ",
                                                     qr/^($inventories_disjunction)$/,
                                                     "> Veuillez saisir un nom d'inventaire valide : ");
            my $inventory_to_open_ref = retrieve encode("CP-1252", "$FindBin::Bin/inventories/$inventory_to_open_name");
            manage_inventory($inventory_to_open_ref, $inventory_to_open_name);
        } elsif ($action_choice eq "ren_inv") {
            # Rename an existing inventory
            my $inventory_to_rename = input_check("\n> Entrez le nom de l'inventaire à renommer : ",
                                                  qr/^($inventories_disjunction)$/,
                                                  "> Veuillez saisir un nom d'inventaire valide : ");

            my $inventory_new_name = "";
            while (1) {
                $inventory_new_name = input_check("> Indiquez le nouveau nom de {<MAGENTA_BEGIN>$inventory_to_rename<MAGENTA_END>} : ",
                                                  qr/^[\p{L}\d_-]+$/,
                                                  "> Format non valide. Indiquez le nouveau nom de {<MAGENTA_BEGIN>$inventory_to_rename<MAGENTA_END>} : ");
                last if (not any {$_ eq $inventory_new_name} @inventories);
                print colorize("<RED_BEGIN>Un inventaire porte déjà le nom de \"<MAGENTA_BEGIN>$inventory_new_name<MAGENTA_END>\". Veuillez choisir un nom différent.\n<RED_END>");
            }

            move "$FindBin::Bin/inventories/$inventory_to_rename", encode("CP-1252", "$FindBin::Bin/inventories/$inventory_new_name");
        } elsif ($action_choice eq "rm_inv") {
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
        }
    }
}

# Create a new inventory
# RETURNS : a reference to the newly created inventory hash and its name (string)
sub create_inventory {
    my @inventories = get_inventories();
    my $new_inventory_name = "";

    # Ensure a unique name for the new inventory
    while (1) {
        $new_inventory_name = input_check("\n> Nommez votre nouvel inventaire : ",
                                          qr/^[\p{L}\d_-]+$/,
                                          "> Format non valide. Nommez votre nouvel inventaire : ");
        last if (not any {$_ eq $new_inventory_name} @inventories);
        print colorize("<RED_BEGIN>Un inventaire porte déjà le nom de \"<MAGENTA_BEGIN>$new_inventory_name<MAGENTA_END>\". Veuillez choisir un nom différent.\n<RED_END>");
    }

    print "\nEntrez les noms des macro-catégories que contiendra votre inventaire.\n";
    print "(Pour terminer le processus, entrez simplement / en guise de dernière catégorie)\n";
    my $macrocategory_number = 1;
    my @macrocategories;
    
    # Loop to gather macro-category names
    my $macrocategory_name = input_check("> Catégorie 1 : ",
                                         qr/^[^\s\/](.*[^\s])*$/,
                                         "Vous devez entrer au moins une catégorie valide !\n> Catégorie 1 : ");
    while ($macrocategory_name ne "/") {
        push @macrocategories, $macrocategory_name;
        $macrocategory_name = input_check("> Catégorie " . ++$macrocategory_number . " : ",
                                          qr/^[^\s](.*[^\s])*$/,
                                          "> Format non valide. Catégorie " . $macrocategory_number . " : ");
    }
    
    # Create a new inventory and return it
    my %new_inventory = new_inventory(@macrocategories);
    print "\nNouvel inventaire créé !\n\n";
    sleep 2;
    return (\%new_inventory, $new_inventory_name);
}

# Steer the general management possibilities at the opening of any inventory
# PARAMS : current category reference (initially whole inventory) and inventory name (string)
sub manage_inventory {
    my ($inventory_ref, $inventory_name) = @_;
    my $curr_category_ref = $inventory_ref;
    my $action_result = "";

    # Main loop for managing a given inventory
    while ($action_result !~ /^EXIT/) {
        # Display available options and prompt for user choice
        my $action_choice = display_inventory_options($curr_category_ref, $inventory_name);
        # Perform the chosen action and receive the result
        $action_result = do_action($action_choice, $curr_category_ref);
        # Update the current category reference if the action has involved any inventory modification, otherwise save it
        if (ref $action_result eq "HASH") {
            $curr_category_ref = $action_result;
        } else {
            store $inventory_ref, encode("CP-1252", "$FindBin::Bin/inventories/$inventory_name") if $action_result =~ /-SV$/;
        }
    }
}

{
    # Variables keeping track of the current path of subcategories the user has dove into
    my @subcategories_refs_depth;
    my @subcategories_names_depth;

    # Display possible actions to perform in the current category, conditionally to its state, and prompt the user to choose one
    # PARAMS : current category reference and inventory name (string)
    # RETURNS : available action chosen by the user (string)
    sub display_inventory_options {
        my ($curr_category_ref, $inventory_name) = @_;

        # Get the actual current subcategories and items (by dereferencing the date structures)
        my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref)};
        my @curr_items = @{get_curr_items_ref($curr_category_ref)};

        my $option_nb = 0;
        my %valid_options;

        # Display information about the current inventory/category state
        print "-" x 100;
        print "\nInventaire {". colored($inventory_name, "magenta") . "} ";
        print scalar @subcategories_names_depth != 0 ?
                "| Catégorie [" . colored(join("/", @subcategories_names_depth), "green") . "] : \n\n" :
                ":\n\n";
        print category_to_string($curr_category_ref);

        # Display available actions, depending on the current category state
        print "\nActions :\n";
        if (scalar @curr_subcategories != 0) {
            print ++$option_nb . ". Aller dans une catégorie\n";
            $valid_options{$option_nb} = "go_to";
        }
        if (scalar @subcategories_refs_depth != 0) {
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
        if (scalar @subcategories_refs_depth != 0) {
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

        # Prompt for user choice
        my $valid_options_disjunction = join "|", keys %valid_options;
        my $option_choice_nb = input_check("> Entrez le numéro de l'action à effectuer : ",
                                           qr/^($valid_options_disjunction)$/,
                                           "> Veuillez entrer un numéro d'action valide : ");
        # Return the chosen action
        return $valid_options{$option_choice_nb};
    }

    # Perform on the current inventory category the action chosen by the user, prompting him for additional information if needed
    # PARAMS : action to perform (string) and current category reference
    # RETURNS : current category reference (maybe changed) or exit message (string)
    sub do_action {
        my ($action, $curr_category_ref) = @_;

        my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref)};
        my $curr_subcategories_disjunction = join "|", @curr_subcategories;
        my @curr_items = @{get_curr_items_ref($curr_category_ref)};
        my $curr_items_disjunction = join "|", @curr_items;

        # Check the chosen action and perform the corresponding operation
        if ($action eq "go_to") {
            # Go into a subcategory
            push @subcategories_refs_depth, $curr_category_ref;
            my $new_curr_category = input_check("> Entrez le nom de la catégorie vers laquelle se déplacer : ",
                                                qr/^($curr_subcategories_disjunction)$/,
                                                "> Veuillez entrer un nom de catégorie valide : ");
            $curr_category_ref = $curr_category_ref->{$new_curr_category};
            push @subcategories_names_depth, $new_curr_category;  
        } elsif ($action eq "go_up") {
            # Go up one level in categories
            $curr_category_ref = pop @subcategories_refs_depth;
            pop @subcategories_names_depth;
        } elsif ($action eq "add_cat") {
            # Add a new category
            my $new_category_name = "";

            # Ensure that the new category name is valid and not already in use in the current categories
            while (1) {
                $new_category_name = input_check("> Entrez le nom de votre nouvelle catégorie : ",
                                                 qr/^[^\s](.*[^\s])*$/,
                                                 "> Format non valide. Entrez le nom de votre nouvelle catégorie : ");
                last if (not any {$_ eq $new_category_name} @curr_subcategories);
                print colorize("<RED_BEGIN>Une catégorie porte déjà le nom de \"<GREEN_BEGIN>$new_category_name<GREEN_END>\". Veuillez choisir un nom différent.\n<RED_END>");
            }

            add_category($curr_category_ref, $new_category_name);
        } elsif ($action eq "ren_cat") {
            # Rename a category
            my $category_to_rename = input_check("> Entrez le nom de la catégorie à renommer : ",
                                                 qr/^($curr_subcategories_disjunction)$/,
                                                 "> Veuillez entrer un nom de catégorie valide : ");
            my $category_new_name = "";

            # Ensure that the new category name is valid and not already in use in the current categories
            while (1) {
                $category_new_name = input_check("> Entrez le nouveau nom de [<GREEN_BEGIN>$category_to_rename<GREEN_END>] : ",
                                                 qr/^[^\s](.*[^\s])*$/,
                                                 "> Format non valide. Entrez le nouveau nom de [<GREEN_BEGIN>$category_to_rename<GREEN_END>] : ");
                last if (not any {$_ eq $category_new_name} @curr_subcategories);
                print colorize("<RED_BEGIN>Une catégorie porte déjà le nom de \"<GREEN_BEGIN>$category_new_name<GREEN_END>\". Veuillez choisir un nom différent.\n<RED_END>");
            }
            
            rename_category($curr_category_ref, $category_to_rename, $category_new_name);
        } elsif ($action eq "mv_cat") {
            # Move a category
            
        } elsif ($action eq "rm_cat") {
            # Remove a category
            my $category_to_remove = input_check("> Entrez le nom de la catégorie à supprimer : ",
                                                 qr/^($curr_subcategories_disjunction)$/,
                                                 "> Veuillez entrer un nom de catégorie valide : ");

            my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref->{$category_to_remove})};
            my @curr_items = @{get_curr_items_ref($curr_category_ref->{$category_to_remove})};

            # Check if the category to remove has no subcategories and no items
            if ((scalar @curr_subcategories == 0) and (scalar @curr_items == 0)) {
                # Remove the category if it is empty
                remove_category($curr_category_ref, $category_to_remove);
            } else {
                # Category contains elements, ask for confirmation
                my $rm_confirm = input_check(
                    "\n> La catégorie [<GREEN_BEGIN>"
                        . $category_to_remove
                        . "<GREEN_END>] contient des éléments. Êtes-vous certain de vouloir supprimer tout son contenu (o/n) ? ",
                    qr/^[on]$/i,
                    "> Choix non valide. Êtes-vous sûr de vouloir supprimer [<GREEN_BEGIN>$category_to_remove<GREEN_END>] (o/n) ? ");
                # Remove the category if the user confirms
                remove_category($curr_category_ref, $category_to_remove) if ($rm_confirm =~ /^[oO]$/);
            }
        } elsif ($action eq "add_it") {
            # Add a new item
            my $new_item = input_check("> Entrez le nom du nouvel item : ",
                                       qr/^[^\s](.*[^\s])*$/,
                                       "> Format non valide. Entrez le nom du nouvel item : ");
            add_item($curr_category_ref, $new_item);
        } elsif ($action eq "ren_it") {
            # Rename an item
            my $item_to_rename = input_check("> Entrez le nom de l'item à renommer : ",
                                             qr/^($curr_items_disjunction)$/,
                                             "> Veuillez entrer un nom d'item valide : ");
            my $item_new_name = input_check("> Entrez le nouveau nom de \"<YELLOW_BEGIN>$item_to_rename<YELLOW_END>\" : ",
                                            qr/^[^\s](.*[^\s])*$/,
                                            "> Format non valide. Entrez le nouveau nom de \"<YELLOW_BEGIN>$item_to_rename<YELLOW_END>\" : ");
            rename_item($curr_category_ref, $item_to_rename, $item_new_name);
        } elsif ($action eq "mv_it") {
            # Move an item
            
        } elsif ($action eq "rm_it") {
            # Remove an item
            my $item_to_remove = input_check("> Entrez le nom de l'item à supprimer ? ",
                                             qr/^($curr_items_disjunction)$/,
                                             "> Veuillez entrer un nom d'item valide : ");
            remove_item($curr_category_ref, $item_to_remove);
        } elsif ($action eq "quit_save") {
            # Quit and save the inventory
            @subcategories_names_depth = ();
            return "EXIT-SV";
        } elsif ($action eq "quit_nosave") {
            # Quit without saving the inventory
            @subcategories_names_depth = ();
            return "EXIT";
        }
        return $curr_category_ref;
    }
}

# Utility routine: gather the names of all previously created inventories
# RETURNS : list of all inventories currently available in the "inventories" folder (strings)
sub get_inventories {
    my @inventories_paths = glob "$FindBin::Bin/inventories/*";
    my @inventories = grep {$_ =~ s/.+\/(.+)/$1/} @inventories_paths;
    return @inventories;

}

# Utility routine: prompt message, check user input and display error message if needed
# PARAMS : a prompt message (string), 
#          a regular expression pattern to test the user input with
#          and a message to display in case of mismatch (string)
# RETURNS : the finally accepted user input
sub input_check {
    my ($prompt_message, $pattern, $fail_message) = @_;
    print colorize("<CYAN_BEGIN>" . $prompt_message . "<CYAN_END>");
    my $user_input = <STDIN>;
    chomp $user_input;
    while ($user_input !~ $pattern) {
        print colorize("<RED_BEGIN>" . $fail_message . "<RED_END>");
        $user_input = <STDIN>;
        chomp $user_input;
    }
    return $user_input;
}

# Utility routine: integrate nested colors schemes
# PARAMS : a string containing schemes of <COLOR_BEGIN> and <COLOR_END>
# RETURNS : the input string with all schemes properly replaced with corresponding colors
sub colorize {
    my ($string) = @_;

    my @color_stack;
    my @strings_to_colorize = grep { $_ ne '' } split(/<[A-Z]+_(?:BEGIN|END)>/, $string);
    my $colorized_string;

    my $color_boundaries_counter = 0;
    while ($string =~ /<([A-Z]+)_(BEGIN|END)>/g) {
        if ($2 eq "BEGIN") {
            push @color_stack, $1;
        } elsif ($2 eq "END") {
            pop @color_stack;
        }
        $colorized_string .= colored($strings_to_colorize[$color_boundaries_counter], lc $color_stack[-1]);
        $color_boundaries_counter++;
        if ($color_boundaries_counter == @strings_to_colorize) {
            last;
        }
    }
    return $colorized_string;
}


main_loop_menu();