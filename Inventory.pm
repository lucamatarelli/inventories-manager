=head1 NAME

Inventory - Module for low-level manipulation routines on inventory data structure

=head1 SYNOPSIS

    use Inventory;

    # Create a new inventory with specified macro-categories
    my %new_inventory = new_inventory('Category1', 'Category2', ...);

    # Add a new item to the current category
    add_item($curr_category_ref, 'New_Item');

    # Move an item from one category to another
    move_item($curr_category_ref, $target_category_ref, 'Item_to_Move');

    # Add a new category to the current category
    add_category($curr_category_ref, 'New_Category');

    # Convert the current category structure to a string representation
    my $category_string = category_to_string($curr_category_ref);

    # Remove a category from the current category
    remove_category($curr_category_ref, 'Category_to_Remove');

=head1 DESCRIPTION

The Inventory module provides low-level manipulation routines for handling inventory data structures. It includes functions for managing items and categories within an inventory.

=head1 EXPORTED FUNCTIONS

=head2 new_inventory(@categories)

Create a new inventory with the specified macro-categories.

=head2 get_curr_items_ref($curr_category_ref)

Return a reference to the current items in the given category.

=head2 get_curr_subcategories_ref($curr_category_ref)

Return a reference to the current subcategories in the given category.

=head2 add_item($curr_category_ref, $new_item)

Add a new item to the current category.

=head2 rename_item($curr_category_ref, $item, $new_name)

Rename an existing item in the current category.

=head2 remove_item($curr_category_ref, $item)

Remove an item from the current category.

=head2 move_item($curr_category_ref, $target_category_ref, $item)

Move an item from one category to another.

=head2 add_category($curr_category_ref, $new_category)

Add a new subcategory to the current category.

=head2 category_to_string($curr_category_ref)

Convert the current category structure to a string representation.

=head2 rename_category($curr_category_ref, $category, $new_name)

Rename an existing subcategory in the current category.

=head2 remove_category($curr_category_ref, $category)

Remove a subcategory from the current category.

=head2 move_category($curr_category_ref, $target_category_ref, $category)

Move a subcategory from one category to another.

=head1 AUTHOR

Luca Matarelli

=cut

package Inventory;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    new_inventory
    get_curr_items_ref get_curr_subcategories_ref
    add_item rename_item remove_item move_item
    add_category category_to_string rename_category remove_category move_category
);

use List::Util qw(first);
use Term::ANSIColor;
use Unicode::Collate;

sub new_inventory {
    my @categories = @_;
    my %new_inventory;
    $new_inventory{$_} = {items => []} for (@categories);
    return %new_inventory;
}

sub get_curr_items_ref {
    my ($curr_category_ref) = @_;
    my $curr_items_ref = defined $curr_category_ref->{items} ? $curr_category_ref->{items} : [];
    return $curr_items_ref;
}

sub get_curr_subcategories_ref {
    my ($curr_category_ref) = @_;
    my @curr_subcategories = grep {$_ ne "items"} keys %$curr_category_ref;
    return \@curr_subcategories;
}

sub add_item {
    my ($curr_category_ref, $new_item) = @_;
    push @{get_curr_items_ref($curr_category_ref)}, $new_item;
}

sub rename_item {
    my ($curr_category_ref, $item, $new_name) = @_;
    for (@{get_curr_items_ref($curr_category_ref)}) {
        $_ = $new_name if ($_ eq $item);
    }
}

sub remove_item {
    my ($curr_category_ref, $item) = @_;
    my @curr_items = @{get_curr_items_ref($curr_category_ref)};
    my $item_index = first {$curr_items[$_] eq $item} 0..@curr_items-1;
    splice(@{get_curr_items_ref($curr_category_ref)}, $item_index, 1);
}

sub move_item {
    my ($curr_category_ref, $target_category_ref, $item) = @_;
    remove_item($curr_category_ref, $item);
    add_item($target_category_ref, $item);
}

sub add_category {
    my ($curr_category_ref, $new_category) = @_;
    $curr_category_ref->{$new_category} = {items => []};
}

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

sub rename_category {
    my ($curr_category_ref, $category, $new_name) = @_;
    $curr_category_ref->{$new_name} = delete $curr_category_ref->{$category};
}

sub remove_category {
    my ($curr_category_ref, $category) = @_;
    return delete $curr_category_ref->{$category};
}

sub move_category {
    my ($curr_category_ref, $target_category_ref, $category) = @_;
    my $moving_category_ref = remove_category($curr_category_ref, $category);
    $target_category_ref->{$category} = $moving_category_ref;
}

1;