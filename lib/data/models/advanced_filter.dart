class AdvancedFilter {
  bool showStatusRed = true;
  bool showStatusOrange = true;
  bool showStatusGreen = true;
  bool showStatusBlue = true;
  List<String> searchPaths = []; //All games inside these search paths will show
  int showErrors = 2;
  int showChanges = 2;
  int showImages =2;
  int showConfiguration=2;

  AdvancedFilter(this.searchPaths);

  AdvancedFilter.fromJson(Map<String, dynamic> json) {
    searchPaths = json['searchPaths'].map<String>((e) => e as String).toList();
    showStatusRed = json['showStatusRed'];
    showStatusOrange = json['showStatusOrange'];
    showStatusBlue = json['showStatusBlue'];
    showErrors = json['showErrors'];
    showChanges = json['showChanges'];
    showImages = json['showImages'];
    showConfiguration = json['showConfiguration'];
  }

  Map<String, dynamic> toJson() {
    return {
      'searchPaths': searchPaths,
      'showStatusRed': showStatusRed,
      'showStatusOrange': showStatusOrange,
      'showStatusBlue': showStatusBlue,
      'showErrors': showErrors,
      'showChanges': showChanges,
      'showImages': showImages,
      'showConfiguration': showConfiguration,
    };
  }

  void reset(List<String> searchPaths) {
    showStatusRed = true;
    showStatusOrange = true;
    showStatusGreen = true;
    showStatusBlue = true;
    this.searchPaths = searchPaths;
    showErrors = 2;
    showChanges = 2;
    showImages =2;
    showConfiguration=2;
  }
}