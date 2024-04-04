# inventories.pl
# This main script provides a simple inventory management system through CLI.
# Users can create, open, rename, and delete inventories, manage categories,
# and perform various actions within the inventory system.

use strict;
use warnings;
use utf8;

my $curr_dir;
BEGIN {
    # Add the current directory to the @INC array to load local modules
    use Encode qw(encode);
    use FindBin qw($Bin);
    $curr_dir = encode("CP-1252", $FindBin::Bin);
    push @INC, $curr_dir;
}

our $lh;
BEGIN {
    # Localization module loading
    use L10N;
    $lh = L10N->get_handle()
        or die "Impossible to load the localization module: $!\n";
    my $language = $lh->language_tag;

    # Install dependencies if needed
    my $install_dependencies_status = system "perl install_dependencies.pl $language";
    exit 1 if $install_dependencies_status != 0;
}
sub say_localized { L10N::say_localized($lh, @_); }

use File::Copy qw(move);
use List::Util qw(any);
use Storable qw(retrieve);
use Term::ANSIColor qw(colored);

# Importing necessary internal modules and routines
require InventoryManipulation;
InventoryManipulation->import();
require Utilities;
Utilities->import();

# Encoding layer for properly displayed CLI interactions
if ($^O eq "MSWin32") {
    binmode STDOUT, ":encoding(CP-850)";
    binmode STDIN, ":encoding(CP-850)";
} else {
    binmode STDOUT, ":encoding(UTF-8)";
    binmode STDIN, ":encoding(UTF-8)";
}

# Main user interface loop for handling general actions
sub main_loop_menu {
    my $chosen_main_action = "";
    while ($chosen_main_action ne "EXIT") {        
        my @available_inventories = get_inventories();

        display_inventories(@available_inventories);
        my $valid_main_options_ref = display_main_menu(@available_inventories);
        $chosen_main_action = get_user_choice($valid_main_options_ref);
        perform_main_action($chosen_main_action, @available_inventories);
    }
}

# Display available inventories
# PARAMS : list of all inventories currently available in the "inventories" folder (strings)
sub display_inventories {
    my (@inventories) = @_;

    print "_" x 100 . "\n";
    if (scalar @inventories == 0) {
        say_localized("no_inventories");
    } else {
        say_localized("inventories");
        print "-> " . colored($_ . "\n", "magenta") for (@inventories);
    }
}

# Display main menu options
# PARAMS : list of all inventories currently available in the "inventories" folder (strings)
# RETURNS : a reference to a hash containing the valid options for the main menu
sub display_main_menu {
    my (@inventories) = @_;

    my $option_nb = 0;
    my %valid_options;

    say_localized("wish");

    say_localized("add_inventory", ++$option_nb);
    $valid_options{$option_nb} = "add_inv";
    if (scalar @inventories != 0) {
        say_localized("open_inventory", ++$option_nb);
        $valid_options{$option_nb} = "open_inv";
        say_localized("rename_inventory", ++$option_nb);
        $valid_options{$option_nb} = "ren_inv";
        say_localized("remove_inventory", ++$option_nb);
        $valid_options{$option_nb} = "rm_inv";
        say_localized("view_inventory", ++$option_nb);
        $valid_options{$option_nb} = "viz_inv";        
    }
    say_localized("main_exit", ++$option_nb);
    $valid_options{$option_nb} = "EXIT";

    return \%valid_options;
}

# Perform main menu action based on user choice
# PARAMS : the chosen action based on user input (string),
#          list of all inventories currently available in the "inventories" folder (strings)
sub perform_main_action {
    my ($chosen_main_action, @inventories) = @_;    
    my $inventories_disjunction = join "|", @inventories;

    if ($chosen_main_action eq "add_inv") {
        # Add a new inventory
        my ($new_inventory_ref, $new_inventory_name) = add_inventory();
        manage_inventory($new_inventory_ref, $new_inventory_name);
    } elsif ($chosen_main_action eq "open_inv") {
        # Open an existing inventory
        my $inventory_to_open_name = input_check("input_inventory_open", qr/^($inventories_disjunction)$/, "inventory_fail");
        my $inventory_to_open_ref = retrieve($curr_dir . encode("CP-1252", "/inventories/$inventory_to_open_name"))
                                        or die $lh->maketext("inventory_get_error", $inventory_to_open_name, $!);
        manage_inventory($inventory_to_open_ref, $inventory_to_open_name);
    } elsif ($chosen_main_action eq "ren_inv") {
        # Rename an existing inventory
        my $inventory_to_rename = input_check("input_inventory_rename", qr/^($inventories_disjunction)$/, "inventory_fail");

        # Ensure that the new inventory name is valid and not already in use in the current inventories
        my $inventory_new_name = "";
        while (1) {
            $inventory_new_name = input_check("input_inventory_new_name", qr/^[\p{L}\d_-]+$/, "inventory_new_name_fail", $inventory_to_rename);
            last if (not any {$_ eq $inventory_new_name} @inventories);
            print colorize($lh->maketext("inventory_name_taken", $inventory_new_name));
        }

        move($curr_dir . encode("CP-1252", "/inventories/$inventory_to_rename"), $curr_dir . encode("CP-1252", "/inventories/$inventory_new_name"))
            or die $lh->maketext("inventory_rename_error", $inventory_to_rename, $!);
    } elsif ($chosen_main_action eq "rm_inv") {
        # Remove an existing inventory
        my $inventory_to_remove = input_check("input_inventory_remove", qr/^($inventories_disjunction)$/, "inventory_fail");

        my $rm_confirm = input_check("inventory_remove_confirm", qr/^[oyn]$/i, "inventory_remove_confirm_fail", $inventory_to_remove);

        if ($rm_confirm =~ /^[oy]$/i) {
            unlink($curr_dir . encode("CP-1252", "/inventories/$inventory_to_remove"))
                or die $lh->maketext("inventory_remove_error", $inventory_to_remove, $!);
        }           
    } elsif ($chosen_main_action eq "viz_inv") {
        # Save a graph representation of a whole inventory as an external PNG image
        my $inventory_to_visualize_name = input_check("input_inventory_visualization", qr/^($inventories_disjunction)$/, "inventory_fail");
        my $inventory_to_visualize_ref = retrieve($curr_dir . encode("CP-1252", "/inventories/$inventory_to_visualize_name"))
                                            or die $lh->maketext("inventory_get_error", $inventory_to_visualize_name, $!);
        visualize_inventory($inventory_to_visualize_ref, $inventory_to_visualize_name);
        
        say_localized("view_inventory_success", colored($inventory_to_visualize_name, "magenta"), colored("img/$inventory_to_visualize_name.png", "magenta"));
        sleep 2;
    }
}


main_loop_menu();