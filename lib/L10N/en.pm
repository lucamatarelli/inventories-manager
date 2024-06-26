package L10N::en;
use base qw(L10N);

use strict;
use warnings;
use utf8;

our %Lexicon = (
    '_AUTO' => 1,

    missing_modules => "The following modules are not installed: [_1]",
    graphviz_warning => "\nNB: The GraphViz2 module requires the prior installation of the GraphViz graphical visualization software, as well as its addition to the PATH. You can get it at https://www.graphviz.org/download/. Make sure to restart the terminal once the installation is complete.\n",
    install_dependencies => "Do you want to install the missing modules? (y/n) ",
    install_dependencies_success => "Modules installation successful.",
    install_dependencies_error => "Error during the modules installation.",
    install_dependencies_refusal => "The following modules are required to run the script: [_1]\nMake sure to install them before restarting the script.",
    
    no_inventories => "\nNo inventory has been created yet.",
    inventories => "\nAvailable inventories:",
    wish => "\nWhat would you like to do?",
    add_inventory => "[_1]. Add an inventory",
    open_inventory => "[_1]. Open an inventory",
    rename_inventory => "[_1]. Rename an inventory",
    remove_inventory => "[_1]. Remove an inventory",
    view_inventory => "[_1]. View the inventory",
    main_exit => "[_1]. Exit the manager\n",
    input_action_number => "> Enter the number of the action to perform: ",
    input_action_number_fail => "> Please enter a valid action number (1-[_1]): ",

    input_inventory_open => "\n> Enter the name of the inventory to open: ",
    inventory_get_error => "Unable to retrieve the inventory {<MAGENTA_BEGIN>[_1]<MAGENTA_END>}: [_2]\n",
    input_inventory_rename => "\n> Enter the name of the inventory to rename: ",
    input_inventory_new_name => "\n> Enter the new name of {<MAGENTA_BEGIN>[_1]<MAGENTA_END>}: ",
    inventory_new_name_fail => "Invalid format (accepted characters: letters, numbers, - and _)\n> Enter the new name of {<MAGENTA_BEGIN>[_1]<MAGENTA_END>}: ",
    inventory_name_taken => "<RED_BEGIN>An inventory already bears the name of \"<MAGENTA_BEGIN>[_1]<MAGENTA_END>\". Please choose a different name.\n<RED_END>",
    inventory_rename_error => "Unable to rename the inventory {<MAGENTA_BEGIN>[_1]<MAGENTA_END>}: [_2]\n",
    input_inventory_remove => "\n> Enter the name of the inventory to remove: ",
    inventory_remove_confirm => "\nThis operation will irreversibly delete the inventory {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} and its content.\n> Are you sure you want to continue? (y/n) ",
    inventory_remove_confirm_fail => "Invalid choice.\n> Are you sure you want to remove {<MAGENTA_BEGIN>[_1]<MAGENTA_END>}? (y/n) ",
    inventory_remove_error => "Unable to remove the inventory {<MAGENTA_BEGIN>[_1]<MAGENTA_END>}: [_2]\n",
    input_inventory_visualization => "\n> Enter the name of the inventory to visualize: ",
    inventory_fail => "> Please enter a valid inventory name: ",
    view_inventory_success => "\nView of the inventory {[_1]} generated and accessible in [_2].\n",

    input_new_inventory_name => "\n> Name your new inventory: ",
    new_inventory_name_fail => "Invalid format (accepted characters: letters, numbers, - and _)\n> Name your new inventory: ",
    macrocategories_instruction => "\nEnter the names of the macro-categories that your inventory will contain.\n(To end the process, simply enter / as the last category)",
    input_macrocategory => "> Category [_1]: ",
    first_macrocategory_fail => "You must enter at least one valid category (no whitespace at the beginning or end)\n> Category 1: ",
    macrocategory_fail => "Invalid format (no whitespace at the beginning or end)\n> Category [_1]: ",
    new_inventory_success => "\nThe inventory {[_1]} has been successfully created!\n",

    current_inventory => "\nInventory {[_1]}",
    current_subcategories => "Category ~[[_1]~]",
    go_into_category => "[_1]. Go into a category",
    go_into_parent_category => "[_1]. Go up a category",
    add_category => "[_1]. Add a category",
    rename_category => "[_1]. Rename a category",
    move_category => "[_1]. Move a category",
    remove_category => "[_1]. Remove a category",
    add_item => "[_1]. Add an item",
    rename_item => "[_1]. Rename an item",
    move_item => "[_1]. Move an item",
    remove_item => "[_1]. Remove an item",
    inventory_save_and_exit => "[_1]. Save the inventory and exit",
    inventory_exit => "[_1]. Exit without saving\n",

    input_category_to_go_into => "> Enter the name of the category to go into: ",
    input_new_category_name => "> Enter the name of your new category: ",
    new_category_name_fail => "Invalid format (no whitespace at the beginning or end)\n> Enter the name of your new category: ",
    category_name_taken => "<RED_BEGIN>A category already bears the name of \"<GREEN_BEGIN>[_1]<GREEN_END>\". Please choose a different name.\n<RED_END>",
    input_category_rename => "> Enter the name of the category to rename: ",
    input_category_new_name => "> Enter the new name of ~[<GREEN_BEGIN>[_1]<GREEN_END>~]: ",
    category_new_name_fail => "Invalid format (no whitespace at the beginning or end)\n> Enter the new name of ~[<GREEN_BEGIN>[_1]<GREEN_END>~]: ",
    input_category_move => "> Enter the name of the category to move: ",
    input_category_remove => "> Enter the name of the category to remove: ",
    category_remove_confirm => "\n The category ~[<GREEN_BEGIN>[_1]<GREEN_END>~] contains elements.\n> Are you sure you want to remove it? (y/n) ",
    category_remove_confirm_fail => "Invalid choice.\n> Are you sure you want to remove ~[<GREEN_BEGIN>[_1]<GREEN_END>~]? (y/n) ",
    category_fail => "> Please enter a valid category name: ",
    input_new_item_name => "> Enter the name of your new item: ",
    new_item_name_fail => "Invalid format (no whitespace at the beginning or end)\n> Enter the name of your new item: ",
    input_item_rename => "> Enter the name of the item to rename: ",
    input_item_new_name => "> Enter the new name of \"<YELLOW_BEGIN>[_1]<YELLOW_END>\": ",
    item_new_name_fail => "Invalid format (no whitespace at the beginning or end)\n> Enter the new name of \"<YELLOW_BEGIN>[_1]<YELLOW_END>\": ",
    input_item_move => "> Enter the name of the item to move: ",
    input_item_remove => "> Enter the name of the item to remove: ",
    item_fail => "> Please enter a valid item name: ",
    inventory_set_error => "Unable to save the inventory {<MAGENTA_BEGIN>[_1]<MAGENTA_END>}: [_2]\n",

    moving_category => "\nMoving in progress: Category ~[[_1]~]",
    moving_item => "\nMoving in progress: Item \"[_1]\"",
    current_moving_category => "=> Category ~[[_1]~]\n",
    move_category_here => "[_1]. Move the category here",
    move_item_here => "[_1]. Move the item here",
    moving_cancel => "[_1]. Cancel the move\n",
    move_inside_moving_category => "You cannot enter the category you wish to move.\n",
    move_category_taken => "<RED_BEGIN>A category already bears the name of \"<GREEN_BEGIN>[_1]<GREEN_END>\" here.\nPlease choose a different category or cancel the move and rename your category.\n<RED_END>",

    img_directory_error => "Unable to create the 'img' directory: [_1]\n",
    png_visualization_error => "Unable to generate the PNG file of the inventory: [_1]\n",
    inventories_directory_error => "Unable to create the 'inventories' directory: [_1]\n",
);

1;