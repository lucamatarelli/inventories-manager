# InventoryStructure.pm
# Module providing low-level manipulation routines for handling inventory data structures.
# It includes functions for managing items and (sub)categories within an inventory.
package InventoryStructure;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    new_inventory
    get_curr_items_ref get_curr_subcategories_ref
    add_item rename_item remove_item move_item
    add_category category_to_string rename_category remove_category move_category
);

use strict;
use warnings;
use utf8;

use List::Util qw(first);
use Term::ANSIColor qw(colored);
use Unicode::Collate;

# Create a new inventory with the specified macro-categories
# PARAMS : list of macro-categories (strings)
# RETURNS : a hash representing the new inventory structure
sub new_inventory {
    my @categories = @_;
    my %new_inventory;
    $new_inventory{$_} = {items => []} for (@categories);
    return %new_inventory;
}

# Return a reference to the current items in the given category
# PARAMS : reference to the current category hash
# RETURNS : reference to the list of items in the current category
sub get_curr_items_ref {
    my ($curr_category_ref) = @_;
    my $curr_items_ref = defined $curr_category_ref->{items} ? $curr_category_ref->{items} : [];
    return $curr_items_ref;
}

# Return a reference to the current subcategories in the given category
# PARAMS : reference to the current category hash
# RETURNS : reference to the list of subcategories in the current category
sub get_curr_subcategories_ref {
    my ($curr_category_ref) = @_;
    my @curr_subcategories = grep {$_ ne "items"} keys %$curr_category_ref;
    return \@curr_subcategories;
}

# Add a new item to the current category
# PARAMS : reference to the current category hash, new item (string)
sub add_item {
    my ($curr_category_ref, $new_item) = @_;
    push @{get_curr_items_ref($curr_category_ref)}, $new_item;
}

# Rename an existing item in the current category
# PARAMS : reference to the current category hash, item to rename (string), new name (string)
sub rename_item {
    my ($curr_category_ref, $item, $new_name) = @_;
    for (@{get_curr_items_ref($curr_category_ref)}) {
        $_ = $new_name if ($_ eq $item);
    }
}

# Remove an item from the current category
# PARAMS : reference to the current category hash, item to remove (string)
sub remove_item {
    my ($curr_category_ref, $item) = @_;
    my @curr_items = @{get_curr_items_ref($curr_category_ref)};
    my $item_index = first {$curr_items[$_] eq $item} 0..@curr_items-1;
    splice(@{get_curr_items_ref($curr_category_ref)}, $item_index, 1);
}

# Move an item from one category to another
# PARAMS : reference to the current category hash, reference to the moving target category hash, item to move (string)
sub move_item {
    my ($curr_category_ref, $target_category_ref, $item) = @_;
    remove_item($curr_category_ref, $item);
    add_item($target_category_ref, $item);
}

# Add a new subcategory to the current category
# PARAMS : reference to the current category hash, new subcategory (string)
sub add_category {
    my ($curr_category_ref, $new_category) = @_;
    $curr_category_ref->{$new_category} = {items => []};
}

# Convert the current category structure to a string representation
# PARAMS : reference to the current category hash
# RETURNS : string representation of the current category
sub category_to_string {
    my ($curr_category_ref) = @_;
    my $category_content = "";
    my @curr_items = @{get_curr_items_ref($curr_category_ref)};
    my $Collator = Unicode::Collate->new();
    my @curr_subcategories_sorted = $Collator->sort(@{get_curr_subcategories_ref($curr_category_ref)});
    if (scalar @curr_subcategories_sorted != 0) {
        $category_content .= "[" . colored($_, "green") . "]" . "\n" for (@curr_subcategories_sorted);
    }
    if (scalar @curr_items != 0) {
        $category_content .= "- " . colored($_, "yellow") . "\n" for (@curr_items);
    }
    return $category_content;
}

# Rename an existing subcategory in the current category
# PARAMS : reference to the current category hash, subcategory to rename (string), new name (string)
sub rename_category {
    my ($curr_category_ref, $category, $new_name) = @_;
    $curr_category_ref->{$new_name} = delete $curr_category_ref->{$category};
}

# Remove a subcategory from the current category
# PARAMS : reference to the current category hash, subcategory to remove (string)
sub remove_category {
    my ($curr_category_ref, $category) = @_;
    return delete $curr_category_ref->{$category};
}

# Move a subcategory from one category to another.
# PARAMS : reference to the current category hash, reference to the moving target category hash, subcategory to move (string)
sub move_category {
    my ($curr_category_ref, $target_category_ref, $category) = @_;
    my $moving_category_ref = remove_category($curr_category_ref, $category);
    $target_category_ref->{$category} = $moving_category_ref;
}

1;