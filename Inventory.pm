package Inventory;

use strict;
use warnings;

use List::Util qw(first);

sub new_inventory {
    my @categories = @_;
    my %new_inventory;
    $new_inventory{$_} = {items => []} for (@categories);
    return %new_inventory;
}

sub add_item {
    my ($category_ref, $new_item) = @_;
    push @{$category_ref->{items}}, $new_item;
}

sub rename_item {
    my ($category_ref, $item, $new_name) = @_;
    for (@{$category_ref->{items}}) {
        $_ = $new_name if ($_ eq $item);
    }
}

sub remove_item {
    my ($category_ref, $item) = @_;
    my @current_items = @{$category_ref->{items}};
    my $item_index = first {$current_items[$_] eq $item} 0..@current_items-1;
    splice(@{$category_ref->{items}}, $item_index);
}

sub add_category {
    my ($category_ref, $new_category) = @_;
    $category_ref->{$new_category} = {items => []};
}

sub rename_category {}

sub move_category {}

sub remove_category {}

1;