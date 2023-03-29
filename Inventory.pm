package Inventory;

use strict;
use warnings;

sub create_inventory {
    my @categories = @_;
    my %new_inventory;
    $new_inventory{$_} = [] for (@categories);
    return %new_inventory;
}

sub add_item {
    my ($inventory_ref, $category, $item) = @_;
    push @{$inventory_ref->{$category}}, $item;
    return 1;
}

sub edit_item {}

sub remove_item {}

sub add_category {
    my ($inventory_ref, $category) = @_;
    $inventory_ref->{$category} = [];
    return 1;
}

sub rename_category {}

sub move_category {}

sub remove_category {}

1;