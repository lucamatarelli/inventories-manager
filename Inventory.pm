package Inventory;

use strict;
use warnings;

sub new_inventory {
    my @categories = @_;
    my %new_inventory;
    $new_inventory{$_} = {items => []} for (@categories);
    return %new_inventory;
}

sub add_item {
    my ($category_ref, $new_item) = @_;
    push @{$category_ref->{items}}, $new_item;
    return 1;
}

sub rename_item {
    my ($category_ref, $item, $new_name) = @_;
    $category_ref->{items}[$item] = $new_name;
}

sub remove_item {}

sub add_category {
    my ($category_ref, $new_category) = @_;
    $category_ref->{$new_category} = {items => []};
    return 1;
}

sub rename_category {}

sub move_category {}

sub remove_category {}

1;