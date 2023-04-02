package Inventory;

use strict;
use warnings;
use utf8;

use List::Util qw(first);

sub new_inventory {
    my @categories = @_;
    my %new_inventory;
    $new_inventory{$_} = {items => []} for (@categories);
    return %new_inventory;
}

sub add_item {
    my ($curr_category_ref, $new_item) = @_;
    push @{$curr_category_ref->{items}}, $new_item;
}

sub rename_item {
    my ($curr_category_ref, $item, $new_name) = @_;
    for (@{$curr_category_ref->{items}}) {
        $_ = $new_name if ($_ eq $item);
    }
}

sub move_item {}

sub remove_item {
    my ($curr_category_ref, $item) = @_;
    my @curr_items = @{$curr_category_ref->{items}};
    my $item_index = first {$curr_items[$_] eq $item} 0..@curr_items-1;
    splice(@{$curr_category_ref->{items}}, $item_index);
}

sub add_category {
    my ($curr_category_ref, $new_category) = @_;
    $curr_category_ref->{$new_category} = {items => []};
}

sub category_to_string {
    my ($curr_category_ref) = @_;
    my $category_content = "";
    my @curr_items = @{$curr_category_ref->{items}};
    my @subcategories = grep {$_ ne "items"} keys %$curr_category_ref;
    if (scalar @curr_items != 0) {
        $category_content .= "- " . $_ . "\n" for (@curr_items);
    }
    if (scalar @subcategories != 0) {
        $category_content .= "[" . $_ . "]" . "\n" for (@subcategories);
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
    my %category_items = %{$curr_category_ref->{$category}};
    if ((scalar(keys %category_items) == 1) and (scalar @{$category_items{items}} == 0)) {
        delete $curr_category_ref->{$category};
    } else {
        # Afficher tous les items et sous-catégories (ainsi que leurs tailles respectives) contenus dans $category !
        # print "Cette catégorie contient les items suivants : " . join(" ; ", @category_items) . ".\n";
        print "Êtes-vous certain de vouloir supprimer cette catégorie et ces items ? (o/n) ";
        my $input = <STDIN>;
        while ($input !~ /^o\n|n\n$/i) {
            print "Êtes-vous certain de vouloir supprimer cette catégorie et ces items ? (o/n) ";
            $input = <STDIN>;
        }
        delete $curr_category_ref->{$category} if ($input =~ /o\n/i);
    }
}

1;