class GameFolderStats {
  int fileCount = 0;
  int size = 0;
  DateTime discoverDate = DateTime.now();

  GameFolderStats(this.fileCount, this.size, this.discoverDate);

  GameFolderStats.fromJson(Map<String, dynamic> json) {
    fileCount = json['fileCount'];
    size = json['size'];
    discoverDate = DateTime.fromMillisecondsSinceEpoch(json['discoverDate']);
  }

  Map<String, dynamic> toJson() {
    return {'fileCount': fileCount, 'size': size,  'discoverDate':discoverDate.millisecondsSinceEpoch};
  }
}