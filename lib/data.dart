class WatchData {
  static List<String> watchList = [];

  static bool isOnWatchList(String id){
    if(watchList.contains(id)){
      return true;
    }
    else{
      return false;
    }
  }
}