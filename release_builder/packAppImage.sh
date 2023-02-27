#!/bin/bash

# AppImage builder for Game Miner created by FranjeGueje and edited by HexDump

#Build binaries
cd ..
flutter build linux --release
cd release_builder

#Build GameMiner tar ball
tar cvzf  GameMiner-Linux-Portable.tar.gz -C ../build/linux/x64/release/bundle .

# Requisites
[ -d GameMiner ] && echo -e "*ERROR* \"GameMiner\" directory is present. Goint out!" && exit 1
[ ! -f GameMiner-Linux-Portable.tar.gz ] && echo -e "*ERRROR* \"GameMiner-Linux-Portable.tar.gz\" is not present..." && exit 2
[ ! -f GameMiner.png ] && echo -e "*ERRROR* \"GameMiner.png\" is not present..." && exit 3


# Download de AppImage builder :D
[ -f linuxdeploy-x86_64.AppImage ] && rm linuxdeploy-x86_64.AppImage
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage && chmod +x linuxdeploy-x86_64.AppImage

# Create the skel
mkdir -p GameMiner/usr/bin/

# Extract the GameMiner build on the directory
tar -xzf GameMiner-Linux-Portable.tar.gz -C GameMiner/usr/bin/.

# Build the AppImage
[ -f GameMiner/usr/bin/GameMiner ] && ./linuxdeploy-x86_64.AppImage --appdir GameMiner -e GameMiner/usr/bin/GameMiner --create-desktop-file -i GameMiner.png --output appimage

# Delete all unnecesary files and directories
rm -Rf GameMiner linuxdeploy-x86_64.AppImage

exit 0
