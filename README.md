# Inventory Management System

## Description

This inventory management system is my first medium-scale project carried out with the aim of deepening my knowledge in entry-level software development. It consists of Perl code delivering a simple console-based interface to create and manage personal inventories (provided here that "inventory" = items classified within named categories). With support for both English and French and a set of features for manipulating and structuring inventory data, this program can be easily run to organize and maintain several collections of items through the terminal.

![Typical view of the program running](/assets/demonstration_screenshot.png)

## Installation and usage

First, ensure you have Perl installed on your system. Then, clone the repository and just execute this line from a terminal running inside the project root:

```bash
perl inventories.pl
```

This will ensure that all necessary Perl modules and external dependencies are installed, and only then will launch the inventory management interface.

## Acquired Skills

- Perl Scripting: Gained a solid foundation in Perl, focusing on scripting for data manipulation, automation tasks and user interaction (regex, OS encoding, nested and complex data structures through references).
- Code Packaging: Learned to organize relevant code into coherent subroutines, modules and packages.
- Command-Line Interface: Developed an understanding of how to create and manage a CLI application, enhancing user interaction through the terminal (UX, nested color schemes, user input).
- Localization and Internationalization: Implemented multi-language support, enabling the application to automatically choose between English and French (following the user's locale), thus learning the importance of global software accessibility.
- Data Structure Management: Explored efficient ways to structure and manage data in Perl, using modules for inventory storage, retrieval and graphical visualization.
- Project Management: Practiced version control with Git and GitHub, managing project files and learning the workflow of developing and maintaining software projects.
- Error Handling: Found ways to handle potential FI/FO errors, faulty user input and as much edge cases as possible.

## Known Issues / To Do's

- Localization Enhancements: While basic localization is implemented, more work is welcome to further internationalize the application.
- GUI: Currently, the system operates solely through the command line. A graphical user interface could be developed for a more user-friendly experience.
- OOP: Turn the inventory hashes into proper objects, by making the InventoryStructure.pm file an object-oriented interface.
- Errors: Find ways to handle potential errors more gracefully than just terminate the whole program.
- Code Refactoring: As my understanding of Perl and software development deepens, I plan to refactor some sections of the codebase for better readability, maintainability, and performance.
- Additional Features:
    - Exporting inventory lists to CSV or JSON formats for easy sharing and integration with other systems.
    - Canceling/Escaping current action by going back to the nearest options menu (ReadKey + Multithreading?)
    - Enabling tab-completion when element (inventory/category/item) name is needed in input (Multithreading?)

Your contributions to addressing these issues or enhancing the project are welcome. Please feel free to fork the repository, make your changes, and submit a pull request.