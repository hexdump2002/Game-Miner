tar -C build/linux/x64/release/bundle -acvf GameMiner-Linux-Portable.tar.gz .
flatpak-builder --verbose --force-clean build-dir com.hexdump.GameMiner.json
