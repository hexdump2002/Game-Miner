class GameFolderStats {
  late final String path;

  late final int fileCount;
  late final int sizeInBytes;

  late final int nonAddedGamesCount;
  late final int addedGamesCount;
  late final int fullyAddedGamesCount;

  late final int nonAddedGamesFileCount;
  late final int addedGamesFileCount;
  late final int fullyAddedGamesFileCount;

  late final int nonAddedGamesSizeInBytes;
  late final int addedGamesSizeInBytes;
  late final int fullyAddedGamesSizeInBytes;

  GameFolderStats(
      {required this.path,
      required this.fileCount,
      required this.sizeInBytes,
      required this.nonAddedGamesCount,
      required this.addedGamesCount,
      required this.fullyAddedGamesCount,
      required this.nonAddedGamesSizeInBytes,
      required this.addedGamesSizeInBytes,
      required this.fullyAddedGamesSizeInBytes,
      required this.nonAddedGamesFileCount,
      required this.addedGamesFileCount,
      required this.fullyAddedGamesFileCount});
}
