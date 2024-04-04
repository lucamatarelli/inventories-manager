# InventoryManipulation.pm
# Module containing all high-level manipulation routines related to inventory user management and visualization.
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

use Encode qw(encode);
use FindBin qw($Bin);
my $curr_dir = encode("CP-1252", $FindBin::Bin);
use List::Util qw(any);
use Storable qw(store);
use Term::ANSIColor qw(colored);
use GraphViz2;

use InventoryStructure;
use Utilities;

my $lh = $main::lh;
sub say_localized { &main::say_localized(@_); }

# Create a new inventory
# RETURNS : a reference to the newly created inventory hash and its name (string)
sub add_inventory {
    my @inventories = get_inventories();

    # Ensure that the new inventory name is valid and not already in use in the current inventories
    my $new_inventory_name = "";
    while (1) {
        $new_inventory_name = input_check("input_new_inventory_name", qr/^[\p{L}\d_-]+$/, "new_inventory_name_fail");
        last if (not any {$_ eq $new_inventory_name} @inventories);
        print colorize($lh->maketext("inventory_name_taken", $new_inventory_name));
    }

    say_localized("macrocategories_instruction");

    my $macrocategory_number = 1;
    my @macrocategories;
    
    # Loop to gather macro-category names
    my $macrocategory_name = input_check("input_macrocategory", qr/^[^\s\/](.*[^\s])*$/, "first_macrocategory_fail", $macrocategory_number);
    while ($macrocategory_name ne "/") {
        push @macrocategories, $macrocategory_name;
        $macrocategory_name = input_check("input_macrocategory", qr/^[^\s](.*[^\s])*$/, "macrocategory_fail", ++$macrocategory_number);
    }
    
    # Create a new inventory and return it
    my %new_inventory = new_inventory(@macrocategories);
    say_localized("new_inventory_success", colored($new_inventory_name, "magenta"));
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
        store $inventory_ref, $curr_dir . encode("CP-1252", "/inventories/$inventory_name")
            or die $lh->maketext("inventory_set_error", $inventory_name, $!);
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
        say_localized("current_inventory", colored($inventory_name, "magenta"));
        say_localized("current_subcategories", colored(join("/", @subcategories_depth_names), "green")) if scalar @subcategories_depth_names != 0;
        print "\n";
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

        say_localized("wish");
        if (scalar @curr_subcategories != 0) {
            say_localized("go_into_category", ++$option_nb);
            $valid_options{$option_nb} = "go_to";
        }
        if (scalar @subcategories_depth_refs != 0) {
            say_localized("go_into_parent_category", ++$option_nb);
            $valid_options{$option_nb} = "go_up";
        }
        say_localized("add_category", ++$option_nb);
        $valid_options{$option_nb} = "add_cat";
        if (scalar @curr_subcategories != 0) {
            say_localized("rename_category", ++$option_nb);
            $valid_options{$option_nb} = "ren_cat";
            say_localized("move_category", ++$option_nb);
            $valid_options{$option_nb} = "mv_cat";
            say_localized("remove_category", ++$option_nb);
            $valid_options{$option_nb} = "rm_cat";
        }
        if (scalar @subcategories_depth_refs != 0) {
            say_localized("add_item", ++$option_nb);
            $valid_options{$option_nb} = "add_it";
        }
        if (scalar @curr_items != 0) {
            say_localized("rename_item", ++$option_nb);
            $valid_options{$option_nb} = "ren_it";
            say_localized("move_item", ++$option_nb);
            $valid_options{$option_nb} = "mv_it";
            say_localized("remove_item", ++$option_nb);
            $valid_options{$option_nb} = "rm_it";
        }
        say_localized("inventory_save_and_exit", ++$option_nb);
        $valid_options{$option_nb} = "quit_save";
        say_localized("inventory_exit", ++$option_nb);
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
            my $new_curr_category = input_check("input_category_to_go_into", qr/^($curr_subcategories_disjunction)$/, "category_fail");
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
                $new_category_name = input_check("input_new_category_name", qr/^[^\s](.*[^\s])*$/, "new_category_name_fail");
                last if (not any {$_ eq $new_category_name} @curr_subcategories);
                print colorize($lh->maketext("category_name_taken", $new_category_name));
            }

            add_category($curr_category_ref, $new_category_name);
        } elsif ($action eq "ren_cat") {
            # Rename a category
            my $category_to_rename = input_check("input_category_rename", qr/^($curr_subcategories_disjunction)$/, "category_fail");

            # Ensure that the new category name is valid and not already in use in the current categories
            my $category_new_name = "";
            while (1) {
                $category_new_name = input_check("input_category_new_name", qr/^[^\s](.*[^\s])*$/, "category_new_name_fail", $category_to_rename);
                last if (not any {$_ eq $category_new_name} @curr_subcategories);
                print colorize($lh->maketext("category_name_taken", $category_new_name));
            }
            
            rename_category($curr_category_ref, $category_to_rename, $category_new_name);
        } elsif ($action eq "mv_cat") {
            # Move a category
            my $category_to_move = input_check("input_category_move", qr/^($curr_subcategories_disjunction)$/, "category_fail");

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
            my $category_to_remove = input_check("input_category_remove", qr/^($curr_subcategories_disjunction)$/, "category_fail");

            my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref->{$category_to_remove})};
            my @curr_items = @{get_curr_items_ref($curr_category_ref->{$category_to_remove})};

            # Check if the category to remove has no subcategories and no items
            if ((scalar @curr_subcategories == 0) and (scalar @curr_items == 0)) {
                # Directly remove the category if it is empty
                remove_category($curr_category_ref, $category_to_remove);
            } else {
                # If category contains elements, ask for confirmation
                my $rm_confirm = input_check("category_remove_confirm", qr/^[oyn]$/i, "category_remove_confirm_fail", $category_to_remove);
                # Remove the category if the user confirms
                remove_category($curr_category_ref, $category_to_remove) if ($rm_confirm =~ /^[oy]$/i);
            }
        } elsif ($action eq "add_it") {
            # Add a new item
            my $new_item = input_check("input_new_item_name", qr/^[^\s](.*[^\s])*$/, "new_item_name_fail");
            add_item($curr_category_ref, $new_item);
        } elsif ($action eq "ren_it") {
            # Rename an item
            my $item_to_rename = input_check("input_item_rename", qr/^($curr_items_disjunction)$/, "item_fail");
            my $item_new_name = input_check("input_item_new_name", qr/^[^\s](.*[^\s])*$/, "item_new_name_fail", $item_to_rename);
            rename_item($curr_category_ref, $item_to_rename, $item_new_name);
        } elsif ($action eq "mv_it") {
            # Move an item
            my $item_to_move = input_check("input_item_move", qr/^($curr_items_disjunction)$/, "item_fail");
            
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
            my $item_to_remove = input_check("input_item_remove", qr/^($curr_items_disjunction)$/, "item_fail");
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
        if ($element_to_move_type eq "category") {
            say_localized("moving_category", colored($element_to_move, "green"));
        } elsif ($element_to_move_type eq "item") {
            say_localized("moving_item", colored($element_to_move, "yellow"));
        }

        if (scalar @moving_subcategories_depth_names != 0) {
            say_localized("current_moving_category", colored(join("/", @moving_subcategories_depth_names), "green"));
        } else {
            say_localized("current_moving_category", "...");
        }

        print category_to_string($curr_moving_category_ref);
    }

    # Display possible actions to perform in the current category, conditionally to its state during a moving operation
    # PARAMS : type of element to move (string)
    # RETURNS : a reference to a hash containing the available actions (keys) and their corresponding strings (values)
    sub display_moving_menu {
        my ($curr_moving_category_ref, $element_to_move, $element_to_move_type, @curr_moving_subcategories) = @_;

        my $option_nb = 0;
        my %valid_options;
        
        say_localized("wish");
        if (scalar @curr_moving_subcategories != 0) {
            if ($element_to_move_type eq "category" &&
                !(scalar @curr_moving_subcategories == 1 &&
                  $curr_moving_category_ref->{$curr_moving_subcategories[0]} == $category_to_move_parent_ref->{$element_to_move})) {
                # Prevent from going into the category to move if it is the only one in the current category
                say_localized("go_into_category", ++$option_nb);
                $valid_options{$option_nb} = "go_to";
            } elsif ($element_to_move_type eq "item") {
                say_localized("go_into_category", ++$option_nb);
                $valid_options{$option_nb} = "go_to";
            }
        }
        if (scalar @moving_subcategories_depth_refs != 0) {
            say_localized("go_into_parent_category", ++$option_nb);
            $valid_options{$option_nb} = "go_up";
        }
        if ($element_to_move_type eq "category") {
            say_localized("move_category_here", ++$option_nb);
            $valid_options{$option_nb} = "mv";
        } elsif ($element_to_move_type eq "item" && scalar @moving_subcategories_depth_refs != 0) {
            say_localized("move_item_here", ++$option_nb);
            $valid_options{$option_nb} = "mv";
        }
        say_localized("moving_cancel", ++$option_nb);
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
                $new_curr_moving_category = input_check("input_category_to_go_into", qr/^($curr_moving_subcategories_disjunction)$/, "category_fail");
                # Check whether chosen category is the one to move, and if so, prevent from going into it
                last if $curr_moving_category_ref->{$new_curr_moving_category} != $category_to_move_parent_ref->{$element_to_move};
                print colored($lh->maketext("move_inside_moving_category"), "red");
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
                print colorize($lh->maketext("move_category_taken", $element_to_move));
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
    if (not any {$_ eq "img"} glob "*") {
        mkdir "img"
            or die $lh->maketext("img_directory_error", $!);
    }
    $inventory_graph->run(format => "png", output_file => $curr_dir . encode("CP-1252", "/img/$inventory_name.png"))
        or die $lh->maketext("png_visualization_error", $!);

    # Reapply encoding layer on standard output because "run" method modifies it
    if ($^O eq "MSWin32") {
        binmode STDOUT, ":encoding(CP-850)";
    } else {
        binmode STDOUT, ":encoding(UTF-8)";
    }
}

1;