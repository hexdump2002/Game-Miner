#!/bin/bash

#Build binaries
cd ..
flutter build linux --release
cd release_builder

#Build GameMiner tar ball
tar cvzf  GameMiner-Linux-Portable.tar.gz -C ../build/linux/x64/release/bundle .

# Requisites
[ -d AppDir ] && echo -e "*ERROR* \"AppDir\" directory is present. Goint out!" && exit 1
[ -d build ] && echo -e "*ERROR* \"buir\" directory is present. Goint out!" && exit 2
[ ! -f GameMiner-Linux-Portable.tar.gz ] && echo -e "*ERRROR* \"GameMiner-Linux-Portable.tar.gz\" is not present..." && exit 3
[ ! -f AppImageBuilder.yml ] && echo -e "*ERRROR* \"AppImageBuilder.yml\" is not present..." && exit 4
[ ! -f AppDir.tar.gz ] && echo -e "*ERRROR* \"AppDir.tar.gz\" is not present..." && exit 5


# Download de AppImage builder :D
[ ! -f appimage-builder-x86_64.AppImage ] && wget -O appimage-builder-x86_64.AppImage https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.0-beta.1/appimage-builder-1.0.0-677acbd-x86_64.AppImage && \
    chmod +x appimage-builder-x86_64.AppImage

# Create the skel
tar xvzf AppDir.tar.gz

# Extract the GameMiner build on the directory
tar -xzf GameMiner-Linux-Portable.tar.gz -C AppDir/usr/bin/.

# Make the link and Build the image
cd AppDir/ && ln -s usr/bin/GameMiner . && cd - && [ -f AppDir/usr/bin/GameMiner ] && chmod +x AppDir/usr/bin/GameMiner AppDir/GameMiner && ./appimage-builder-x86_64.AppImage --recipe AppImageBuilder.yml --build-dir build

# Delete all unnecesary files and directories
rm -Rf build/ AppDir/
rm appimage-builder-x86_64.AppImage
# Change the name
[ -f "Game Miner-latest-x86_64.AppImage" ] && mv "Game Miner-latest-x86_64.AppImage" "GameMiner.AppImage"

exit 0
