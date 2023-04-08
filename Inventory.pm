package Inventory;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    new_inventory
    get_curr_items_ref get_curr_subcategories_ref
    add_item rename_item remove_item
    add_category category_to_string rename_category remove_category
);

use List::Util qw(first);

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

sub move_item {}

sub remove_item {
    my ($curr_category_ref, $item) = @_;
    my @curr_items = @{get_curr_items_ref($curr_category_ref)};
    my $item_index = first {$curr_items[$_] eq $item} 0..@curr_items-1;
    splice(@{get_curr_items_ref($curr_category_ref)}, $item_index, 1);
}

sub add_category {
    my ($curr_category_ref, $new_category) = @_;
    $curr_category_ref->{$new_category} = {items => []};
}

sub category_to_string {
    my ($curr_category_ref) = @_;
    my $category_content = "";
    my @curr_items = @{get_curr_items_ref($curr_category_ref)};
    my @curr_subcategories = @{get_curr_subcategories_ref($curr_category_ref)};
    if (scalar @curr_items != 0) {
        $category_content .= "- " . $_ . "\n" for (@curr_items);
    }
    if (scalar @curr_subcategories != 0) {
        $category_content .= "[" . $_ . "]" . "\n" for (@curr_subcategories);
    }
    return $category_content;
}

sub rename_category {
    my ($curr_category_ref, $category, $new_name) = @_;
    $curr_category_ref->{$new_name} = delete $curr_category_ref->{$category};
}

sub move_category {}

sub remove_category {
    my ($curr_category_ref, $category) = @_;
    delete $curr_category_ref->{$category};
}

1;