package L10N::fr;
use base qw(L10N);

use strict;
use warnings;
use utf8;

our %Lexicon = (
    '_AUTO' => 1,

    missing_modules => "Les modules suivants ne sont pas installés : [_1]",
    graphviz_warning => "\nNB : le module GraphViz2 nécessite l'installation préalable du logiciel de visualisation graphique GraphViz, ainsi que son ajout au PATH. Vous pouvez l'obtenir sur https://www.graphviz.org/download/. Veillez à relancer le terminal une fois l'installation terminée.\n",
    install_dependencies => "Voulez-vous installer les modules manquants ? (o/n) ",
    install_dependencies_success => "Installation des modules réussie.",
    install_dependencies_error => "Erreur lors de l'installation des modules.",
    install_dependencies_refusal => "Les modules suivants sont requis pour exécuter le script : [_1]\nVeillez à les installer avant de relancer le script.",
    
    no_inventories => "\nAucun inventaire n'a encore été créé.",
    inventories => "\nInventaires disponibles :",
    wish => "\nQue souhaitez-vous faire ?",
    add_inventory => "[_1]. Ajouter un inventaire",
    open_inventory => "[_1]. Ouvrir un inventaire",
    rename_inventory => "[_1]. Renommer un inventaire",
    remove_inventory => "[_1]. Supprimer un inventaire",
    view_inventory => "[_1]. Visualiser l'inventaire",
    main_exit => "[_1]. Quitter le gestionnaire\n",
    input_action_number => "> Entrez le numéro de l'action à effectuer : ",
    input_action_number_fail => "> Veuillez entrer un numéro d'action valide (1-[_1]) : ",

    input_inventory_open => "\n> Entrez le nom de l'inventaire à ouvrir : ",
    inventory_get_error => "Impossible de récupérer l'inventaire {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} : [_2]\n",
    input_inventory_rename => "\n> Entrez le nom de l'inventaire à renommer : ",
    input_inventory_new_name => "\n> Entrez le nouveau nom de {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} : ",
    inventory_new_name_fail => "Format non valide (caractères acceptés : lettres, chiffres, - et _)\n> Entrez le nouveau nom de {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} : ",
    inventory_name_taken => "<RED_BEGIN>Un inventaire porte déjà le nom de \"<MAGENTA_BEGIN>[_1]<MAGENTA_END>\". Veuillez choisir un nom différent.\n<RED_END>",
    inventory_rename_error => "Impossible de renommer l'inventaire {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} : [_2]\n",
    input_inventory_remove => "\n> Entrez le nom de l'inventaire à supprimer : ",
    inventory_remove_confirm => "\nCette opération supprimera irréversiblement l'inventaire {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} et son contenu.\n> Êtes-vous sûr de vouloir continuer ? (o/n) : ",
    inventory_remove_confirm_fail => "Choix non valide.\n> Êtes-vous sûr de vouloir supprimer {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} (o/n) ? ",
    inventory_remove_error => "Impossible de supprimer l'inventaire {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} : [_2]\n",
    input_inventory_visualization => "\n> Entrez le nom de l'inventaire à visualiser : ",
    inventory_fail => "> Veuillez entrer un nom d'inventaire valide : ",
    view_inventory_success => "\nVisualisation de l'inventaire {[_1]} générée et accessible dans [_2].\n",

    input_new_inventory_name => "\n> Nommez votre nouvel inventaire : ",
    new_inventory_name_fail => "Format non valide (caractères acceptés : lettres, chiffres, - et _)\n> Nommez votre nouvel inventaire : ",
    macrocategories_instruction => "\nEntrez les noms des macro-catégories que contiendra votre inventaire.\n(Pour terminer le processus, entrez simplement / en guise de dernière catégorie)",
    input_macrocategory => "> Catégorie [_1] : ",
    first_macrocategory_fail => "Vous devez entrer au moins une catégorie valide (aucun espace blanc au début ou à la fin)\n> Catégorie 1 : ",
    macrocategory_fail => "Format non valide (aucun espace blanc au début ou à la fin)\n> Catégorie [_1] : ",
    new_inventory_success => "\nL'inventaire {[_1]} a été créé avec succès !\n",

    current_inventory => "\nInventaire {[_1]}",
    current_subcategories => "Catégorie ~[[_1]~]",
    go_into_category => "[_1]. Aller dans une catégorie",
    go_into_parent_category => "[_1]. Remonter d'une catégorie",
    add_category => "[_1]. Ajouter une catégorie",
    rename_category => "[_1]. Renommer une catégorie",
    move_category => "[_1]. Déplacer une catégorie",
    remove_category => "[_1]. Supprimer une catégorie",
    add_item => "[_1]. Ajouter un item",
    rename_item => "[_1]. Renommer un item",
    move_item => "[_1]. Déplacer un item",
    remove_item => "[_1]. Supprimer un item",
    inventory_save_and_exit => "[_1]. Enregistrer l'inventaire et quitter",
    inventory_exit => "[_1]. Quitter sans enregistrer\n",
    
    input_category_to_go_into => "> Entrez le nom de la catégorie vers laquelle se déplacer : ",
    input_new_category_name => "> Entrez le nom de votre nouvelle catégorie : ",
    new_category_name_fail => "Format non valide (aucun espace blanc au début ou à la fin)\n> Entrez le nom de votre nouvelle catégorie : ",
    category_name_taken => "<RED_BEGIN>Une catégorie porte déjà le nom de \"<GREEN_BEGIN>[_1]<GREEN_END>\". Veuillez choisir un nom différent.\n<RED_END>",
    input_category_rename => "> Entrez le nom de la catégorie à renommer : ",
    input_category_new_name => "> Entrez le nouveau nom de ~[<GREEN_BEGIN>[_1]<GREEN_END>~] : ",
    category_new_name_fail => "Format non valide (aucun espace blanc au début ou à la fin)\n> Entrez le nouveau nom de ~[<GREEN_BEGIN>[_1]<GREEN_END>~] : ",
    input_category_move => "> Entrez le nom de la catégorie à déplacer : ",
    input_category_remove => "> Entrez le nom de la catégorie à supprimer : ",
    category_remove_confirm => "\n> La catégorie ~[<GREEN_BEGIN>[_1]<GREEN_END>~] contient des éléments.\n> Êtes-vous sûr de vouloir supprimer tout son contenu (o/n) ? ",
    category_remove_confirm_fail => "Choix non valide.\n> Êtes-vous sûr de vouloir supprimer ~[<GREEN_BEGIN>[_1]<GREEN_END>~] (o/n) ? ",
    category_fail => "> Veuillez entrer un nom de catégorie valide : ",
    input_new_item_name => "> Entrez le nom de votre nouvel item : ",
    new_item_name_fail => "Format non valide (aucun espace blanc au début ou à la fin)\n> Entrez le nom de votre nouvel item : ",
    input_item_rename => "> Entrez le nom de l'item à renommer : ",
    input_item_new_name => "> Entrez le nouveau nom de \"<YELLOW_BEGIN>[_1]<YELLOW_END>\" : ",
    item_new_name_fail => "Format non valide (aucun espace blanc au début ou à la fin)\n> Entrez le nouveau nom de \"<YELLOW_BEGIN>[_1]<YELLOW_END>\" : ",
    input_item_move => "> Entrez le nom de l'item à déplacer : ",
    input_item_remove => "> Entrez le nom de l'item à supprimer : ",
    item_fail => "> Veuillez entrer un nom d'item valide : ",
    inventory_set_error => "Impossible de sauvegarder l'inventaire {<MAGENTA_BEGIN>[_1]<MAGENTA_END>} : [_2]\n",

    moving_category => "\nDéplacement en cours : Catégorie ~[[_1]~]",
    moving_item => "\nDéplacement en cours : Item \"[_1]\"",
    current_moving_category => "=> Catégorie ~[[_1]~]\n",
    move_category_here => "[_1]. Déplacer ici la catégorie",
    move_item_here => "[_1]. Déplacer ici l'item",
    moving_cancel => "[_1]. Annuler le déplacement\n",
    move_inside_moving_category => "Vous ne pouvez pas entrer dans la catégorie que vous désirez déplacer.\n",
    move_category_taken => "<RED_BEGIN>Une catégorie porte déjà le nom de \"<GREEN_BEGIN>[_1]<GREEN_END>\" ici.\nVeuillez choisir une catégorie différente ou annuler le déplacement et renommer votre catégorie.\n<RED_END>",

    img_directory_error => "Impossible de créer le répertoire 'img' : [_1]\n",
    png_visualization_error => "Impossible de générer le fichier PNG de l'inventaire : [_1]\n",
    inventories_directory_error => "Impossible de créer le répertoire 'inventories' : [_1]\n",
);

1;