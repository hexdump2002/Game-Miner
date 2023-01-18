# What is Game Miner?
Game Miner is a set of tools that aliviates the burden of managing and adding non steam games to the steam client. It manages a list of given folders that from now on we will call "The user game library" holding non steam games or any other type of external application that the user wants to add and launch from the steam client.

On the other hand, Game Miner provide with the needed tools to manage non steam application data like compatdata and shaderdata folders that are not deleted when the game/application is removed from the steam client.

Game Miner was created with the steam deck in mind but should work on any linux distribution. If there is enough interest a windows version could be released in the future.

# How does Game Miner looks like?

Game miner has different tools aimed to very specific tasks. Right now it has a Game Manager, a Game Data Manager and a summary tool. The sumary tool is not yet ready for release but will be dropped shortly. 

![Game Manager](/site_images/game_manager.png?raw=true "Game manager")
![Game Data Manager](/site_images/game_data_manager.png?raw=true "Game data manager")
![Settings](/site_images/settings.png?raw=true "Settings")
![User Change](/site_images/change_user.png?raw=true "User change")

# Game Miner tools


### Game Manager and Navigation tools

Use the Game Manager tool to add, remove and edit the games you want to see in your steam library.

The game manager tool also provides an overview of each game status (represented by colored squares), storage stats and also provides diffent actions to apply on the physical folder that holds the game like deleting or renaming.

Game Miner supports multi user so, if more than one steam account is used in your device, you will be able to switch among them clicking on the avatar picture. Settings and configurations are saved by user to avoid configuration clashing.

![Game Manager](/site_images/navigation_and_game_manager_explanation.png?raw=true "Game manager")

Every row in the game manager represents a folder in your game library. They can be expadnded and will show differnt executables that can be added to steam. Try to name each executable with a menaful name if you want to easily find them when you come back to steam. If a default proton is selected in settings, it will be assigned as soon as the executable is added.

![Game Manager](/site_images/game_manager_expanded_explanation.png?raw=true "Game manager")


### Data Manager tool

![Data Manager](/site_images/data_manager_explanation.png?raw=true "Data manager")


### Settings

![Settings](/site_images/settings_explanation.png?raw=true "Settings")


Game is 

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
