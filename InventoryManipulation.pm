# Module containing all high-level manipulation routines related to inventory user management
package InventoryManipulation;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    add_inventory
    manage_inventory
    visualize_inventory
);

use strict;
use warnings;
use utf8;

use FindBin;
use Encode qw(encode);
use List::Util qw(any);
use Storable;
use Term::ANSIColor;
use GraphViz2;

use InventoryStructure;
use Utilities;

# Create a new inventory
# RETURNS : a reference to the newly created inventory hash and its name (string)
sub add_inventory {
    my @inventories = get_inventories();

    # Ensure that the new inventory name is valid and not already in use in the current inventories
    my $new_inventory_name = "";
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
    my $chosen_inventory_action = "";

    # Main loop for managing a given inventory
    while ($chosen_inventory_action !~ /^quit/) {
        display_current_content($curr_category_ref, $inventory_name);
        my $valid_inventory_options_ref = display_inventory_menu($curr_category_ref);
        $chosen_inventory_action = get_user_choice($valid_inventory_options_ref);
        $curr_category_ref = perform_inventory_action($chosen_inventory_action, $curr_category_ref);
    }
    
    # Save the updated inventory if the user chose to quit and save
    if ($chosen_inventory_action eq "quit_save") {
        store $inventory_ref, encode("CP-1252", "$FindBin::Bin/inventories/$inventory_name");
    }
}

{
    # Variables keeping track of the current path of subcategories the user has dove into
    my (@subcategories_depth_refs, @subcategories_depth_names);
    # Variables keeping track of the current path of subcategories the user has dove into during a moving operation
    my (@moving_subcategories_depth_refs, @moving_subcategories_depth_names);
    # Variable keeping track of the parent category of the category to move during a moving operation (to prevent from going into it)
    my $category_to_move_parent_ref;

    # Display information about the current inventory/subcategory state
    # PARAMS : current category reference (hashref) and inventory name (string)
    sub display_current_content {
        my ($curr_category_ref, $inventory_name) = @_;

        print "-" x 100;
        print "\nInventaire {". colored($inventory_name, "magenta") . "} ";
        print scalar @subcategories_depth_names != 0 ?
                "| Catégorie [" . colored(join("/", @subcategories_depth_names), "green") . "] : \n\n" :
                ":\n\n";
        print category_to_string($curr_category_ref);
    }

    # Display possible actions to perform in the current category, conditionally to its state
    # PARAMS : current category reference (hashref)
    # RETURNS : a reference to a hash containing the available actions (keys) and their corresponding strings (values)
    sub display_inventory_menu {
        my ($curr_category_ref) = @_;

        # Get the actual current subcategories and items (by dereferencing the date structures)
        my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref)};
        my @curr_items = @{get_curr_items_ref($curr_category_ref)};

        my $option_nb = 0;
        my %valid_options;

        print "\nActions :\n";
        if (scalar @curr_subcategories != 0) {
            print ++$option_nb . ". Aller dans une catégorie\n";
            $valid_options{$option_nb} = "go_to";
        }
        if (scalar @subcategories_depth_refs != 0) {
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
        if (scalar @subcategories_depth_refs != 0) {
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

        return \%valid_options;
    }

    # Perform on the current inventory category the action chosen by the user, prompting him for additional information if needed
    # PARAMS : action to perform (string) and current category reference (hashref)
    # RETURNS : the potentially updated current category reference (hashref)
    sub perform_inventory_action {
        my ($action, $curr_category_ref) = @_;

        my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref)};
        my $curr_subcategories_disjunction = join "|", @curr_subcategories;
        my @curr_items = @{get_curr_items_ref($curr_category_ref)};
        my $curr_items_disjunction = join "|", @curr_items;

        # Check the chosen action and perform the corresponding operation
        if ($action eq "go_to") {
            # Go into a subcategory
            push @subcategories_depth_refs, $curr_category_ref;
            my $new_curr_category = input_check("> Entrez le nom de la catégorie vers laquelle se déplacer : ",
                                                qr/^($curr_subcategories_disjunction)$/,
                                                "> Veuillez entrer un nom de catégorie valide : ");
            $curr_category_ref = $curr_category_ref->{$new_curr_category};
            push @subcategories_depth_names, $new_curr_category;  
        } elsif ($action eq "go_up") {
            # Go up one level in categories
            $curr_category_ref = pop @subcategories_depth_refs;
            pop @subcategories_depth_names;
        } elsif ($action eq "add_cat") {
            # Add a new category
            # Ensure that the new category name is valid and not already in use in the current categories
            my $new_category_name = "";
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

            # Ensure that the new category name is valid and not already in use in the current categories
            my $category_new_name = "";
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
            my $category_to_move = input_check("> Entrez le nom de la catégorie à déplacer : ",
                                               qr/^($curr_subcategories_disjunction)$/,
                                               "> Veuillez entrer un nom de catégorie valide : ");

            @moving_subcategories_depth_refs = @subcategories_depth_refs;
            @moving_subcategories_depth_names = @subcategories_depth_names;
            $category_to_move_parent_ref = $curr_category_ref;

            my $target_category_ref = moving_element($curr_category_ref, $category_to_move, "category");
            if (defined $target_category_ref) {
                move_category($curr_category_ref, $target_category_ref, $category_to_move);
                
                $curr_category_ref = $target_category_ref;
                @subcategories_depth_refs = @moving_subcategories_depth_refs;
                @subcategories_depth_names = @moving_subcategories_depth_names;
            }
        } elsif ($action eq "rm_cat") {
            # Remove a category
            my $category_to_remove = input_check("> Entrez le nom de la catégorie à supprimer : ",
                                                 qr/^($curr_subcategories_disjunction)$/,
                                                 "> Veuillez entrer un nom de catégorie valide : ");

            my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref->{$category_to_remove})};
            my @curr_items = @{get_curr_items_ref($curr_category_ref->{$category_to_remove})};

            # Check if the category to remove has no subcategories and no items
            if ((scalar @curr_subcategories == 0) and (scalar @curr_items == 0)) {
                # Directly remove the category if it is empty
                remove_category($curr_category_ref, $category_to_remove);
            } else {
                # If category contains elements, ask for confirmation
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
            my $item_to_move = input_check("> Entrez le nom de l'item à déplacer : ",
                                           qr/^($curr_items_disjunction)$/,
                                           "> Veuillez entrer un nom d'item valide : ");
            
            @moving_subcategories_depth_refs = @subcategories_depth_refs;
            @moving_subcategories_depth_names = @subcategories_depth_names;

            my $target_category_ref = moving_element($curr_category_ref, $item_to_move, "item");
            if (defined $target_category_ref) {
                move_item($curr_category_ref, $target_category_ref, $item_to_move);

                $curr_category_ref = $target_category_ref;
                @subcategories_depth_refs = @moving_subcategories_depth_refs;
                @subcategories_depth_names = @moving_subcategories_depth_names;
            }
        } elsif ($action eq "rm_it") {
            # Remove an item
            my $item_to_remove = input_check("> Entrez le nom de l'item à supprimer ? ",
                                             qr/^($curr_items_disjunction)$/,
                                             "> Veuillez entrer un nom d'item valide : ");
            remove_item($curr_category_ref, $item_to_remove);
        } elsif ($action eq "quit_save" or $action eq "quit_nosave") {
            @subcategories_depth_names = ();
        }
        return $curr_category_ref;
    }

    # Recursive subroutine to move an element (category or item) to a new location in the inventory
    # PARAMS : current category reference (hashref), element to move (string), its type (string) and original current category reference (hashref)
    # RETURNS : the potentially updated current category reference (hashref)
    sub moving_element {
        my ($curr_moving_category_ref, $element_to_move, $element_to_move_type) = @_;

        my @curr_moving_subcategories = @{get_curr_subcategories_ref($curr_moving_category_ref)};

        display_moving_current_content($curr_moving_category_ref, $element_to_move, $element_to_move_type);
        my $valid_moving_options_ref = display_moving_menu($curr_moving_category_ref, $element_to_move, $element_to_move_type, @curr_moving_subcategories);
        my $chosen_moving_action = get_user_choice($valid_moving_options_ref);
        return perform_moving_action($chosen_moving_action, $curr_moving_category_ref, $element_to_move, $element_to_move_type, @curr_moving_subcategories);
    }

    # Display information about the current inventory/subcategory state during a moving operation
    # PARAMS : current category reference (hashref), element to move (string) and its type (string)
    sub display_moving_current_content {
        my ($curr_moving_category_ref, $element_to_move, $element_to_move_type) = @_;

        print "~" x 100;
        print "\nDéplacement en cours : ";
        if ($element_to_move_type eq "category") {
            print "catégorie [" . colored($element_to_move, "green") . "]";
        } elsif ($element_to_move_type eq "item") {
            print "item \"" . colored($element_to_move, "yellow") . "\"";
        }
        print scalar @moving_subcategories_depth_names != 0 ?
                " => catégorie [" . colored(join("/", @moving_subcategories_depth_names), "green") . "]\n\n" :
                " => ...\n\n";
        print category_to_string($curr_moving_category_ref);
    }

    # Display possible actions to perform in the current category, conditionally to its state during a moving operation
    # PARAMS : type of element to move (string)
    # RETURNS : a reference to a hash containing the available actions (keys) and their corresponding strings (values)
    sub display_moving_menu {
        my ($curr_moving_category_ref, $element_to_move, $element_to_move_type, @curr_moving_subcategories) = @_;

        my $option_nb = 0;
        my %valid_options;
        
        print "\nActions :\n";
        if (scalar @curr_moving_subcategories != 0) {
            if ($element_to_move_type eq "category" &&
                !(scalar @curr_moving_subcategories == 1 &&
                  $curr_moving_category_ref->{$curr_moving_subcategories[0]} == $category_to_move_parent_ref->{$element_to_move})) {
                # Prevent from going into the category to move if it is the only one in the current category
                print ++$option_nb . ". Aller dans une catégorie\n";
                $valid_options{$option_nb} = "go_to";
            } elsif ($element_to_move_type eq "item") {
                print ++$option_nb . ". Aller dans une catégorie\n";
                $valid_options{$option_nb} = "go_to";
            }
        }
        if (scalar @moving_subcategories_depth_refs != 0) {
            print ++$option_nb . ". Remonter d'une catégorie\n";
            $valid_options{$option_nb} = "go_up";
        }
        if ($element_to_move_type eq "category") {
            print ++$option_nb . ". Déplacer ici la catégorie\n";
            $valid_options{$option_nb} = "mv";
        } elsif ($element_to_move_type eq "item" && scalar @moving_subcategories_depth_refs != 0) {
            print ++$option_nb . ". Déplacer ici l'item\n";
            $valid_options{$option_nb} = "mv";
        }
        print ++$option_nb . ". Annuler le déplacement\n\n";
        $valid_options{$option_nb} = "cancel";

        return \%valid_options;
    }

    # Perform on the current inventory category the action chosen by the user, prompting him for additional information if needed during a moving operation
    # PARAMS : action to perform (string), current category reference (hashref), element to move (string) and its type (string)
    # RETURNS : the potentially updated current category reference (hashref)
    sub perform_moving_action {
        my ($action, $curr_moving_category_ref, $element_to_move, $element_to_move_type, @curr_moving_subcategories) = @_;

        if ($action eq "go_to") {
            # Go into a subcategory
            push @moving_subcategories_depth_refs, $curr_moving_category_ref;
            
            my $curr_moving_subcategories_disjunction = join "|", @curr_moving_subcategories;            
            my $new_curr_moving_category;
            while (1) {
                $new_curr_moving_category = input_check("> Entrez le nom de la catégorie vers laquelle se déplacer : ",
                                                           qr/^($curr_moving_subcategories_disjunction)$/,
                                                           "> Veuillez entrer un nom de catégorie valide : ");
                # Check whether chosen category is the one to move, and if so, prevent from going into it
                last if $curr_moving_category_ref->{$new_curr_moving_category} != $category_to_move_parent_ref->{$element_to_move};
                print colored("Vous ne pouvez pas entrer dans la catégorie que vous désirez déplacer.\n", "red");
            }

            push @moving_subcategories_depth_names, $new_curr_moving_category;
            return moving_element($curr_moving_category_ref->{$new_curr_moving_category}, $element_to_move, $element_to_move_type);
        } elsif ($action eq "go_up") {
            # Go up one level in categories
            pop @moving_subcategories_depth_names;
            return moving_element(pop @moving_subcategories_depth_refs, $element_to_move, $element_to_move_type);
        } elsif ($action eq "mv") {
            # Choose current category to move the element
            if (($element_to_move_type eq "category") && (any {$_ eq $element_to_move} @curr_moving_subcategories)) {
                # Check whether the name of the category to move is not already taken in the current category
                print colorize("<RED_BEGIN>Une catégorie porte déjà le nom de \"<GREEN_BEGIN>$element_to_move<GREEN_END>\" ici.\n"
                      . "Veuillez choisir une catégorie différente ou annuler le déplacement et renommer votre catégorie.\n<RED_END>");
                sleep 3;
                return moving_element($curr_moving_category_ref, $element_to_move, $element_to_move_type);
            }
            return $curr_moving_category_ref;
        } elsif ($action eq "cancel") {
            return undef;
        }
    }
}

# Generate a graphic representation of a whole given inventory, saved to an external image file
# PARAMS : inventory reference (hashref) and inventory name (string)
sub visualize_inventory {
    my ($inventory_ref, $inventory_name) = @_;

    my $inventory_graph = GraphViz2->new(
        edge   => {color => "black"},
        global => {directed => 1},
    );

    # Recursive subroutine to add nodes and edges to the graph
    # PARAMS : the graph object to add nodes and edges to,
    #          the name of the current node's parent (string),
    #          the actual complex data structure to process (hashref)
    sub add_nodes_and_edges {
        my ($graph, $parent, $data) = @_;

        for my $key (keys %$data) {
            my $node = "$parent/$key";

            if ($key eq 'items') {
                # Skip empty "items" nodes        
                next if ref $data->{$key} eq "ARRAY" && !@{$data->{$key}};
            } else {
                # Add the current node if it is not just an "items" key
                $graph->add_node(name => $node, label => $key,
                                 color => "green3", style => "filled");
                $graph->add_edge(from => $parent, to => $node);
            }

            # Recursively process subcategories if the value is a hash reference
            if (ref $data->{$key} eq "HASH") {
                add_nodes_and_edges($graph, $node, $data->{$key});
            } elsif (ref $data->{$key} eq "ARRAY" && @{$data->{$key}}) {
                # Add a node for each item if the value is an array with content
                for my $item (@{$data->{$key}}) {
                    $graph->add_node(name => "$node/$item", label => $item,
                                     shape => "box", color => "yellow3", style => "filled");
                    # Reattach the items to their parent category, glossing over the ignored "items" key
                    $graph->add_edge(from => $node =~ s/\/items//r, to => "$node/$item");
                }
            }
        }
    }

    # Initialize the graph
    $inventory_graph->add_node(name => "root", label => $inventory_name,
                     shape => "diamond", color => "magenta3", style => "filled");

    # Build the graph
    add_nodes_and_edges($inventory_graph, "root", $inventory_ref);

    # Save the graph as external PNG file
    mkdir "img" if not any {$_ eq "img"} glob "*";
    $inventory_graph->run(format => "png", output_file => encode("CP-1252", "$FindBin::Bin/img/$inventory_name.png"));

    # Reapply encoding layer on standard output because "run" method modifies it
    if ($^O eq "MSWin32") {
        binmode STDOUT, ":encoding(CP-850)";
    }
}

1;