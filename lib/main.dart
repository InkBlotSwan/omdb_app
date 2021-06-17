import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:omdb_app/data.dart';
import 'package:omdb_app/database_functions.dart';
import 'package:omdb_app/o_m_dbcons_icons.dart';
import 'package:omdb_app/size_scaling.dart';
import 'package:path/path.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';


//Colours for application.
const Color orange = Color(0xffffa451);
const Color white = Color(0xfff3f1f1);
const Color grey = Color(0xffa0a0a0);
const Color yellow = Color(0xffffc83a);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Entry point for app
  runApp(MaterialApp(home: LandingScreen()));
}

// Initial landing screen, also point of entry for the app.
class LandingScreen extends StatefulWidget {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  //States for widget
  bool showWatchList = false;
  String query = "";
  final queryController = TextEditingController();

  @override
  void initState(){
    super.initState();
    DatabaseFunctions().LoadMovies();
  }

  @override
  void dispose(){
    super.dispose();
    queryController.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Scale(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
            elevation: 0,
            title: Text(
              "OMDb",
              style: TextStyle(
                fontSize: Scale.blockScreenWidth * 10.0,
              ),
            ),
            centerTitle: true,
            backgroundColor: orange,
      ),
      body: GestureDetector(
        onTap: (){
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: ListView(
          children: [
            Container(
              color: orange,
              padding: EdgeInsets.symmetric(horizontal: Scale.blockScreenWidth * 10, vertical: Scale.blockScreenHeight * 7),
              child: Image(
                image: AssetImage("assets/graphic.png"),
                alignment: Alignment.bottomCenter,
              ),
            ),

            Align(
              alignment: Alignment(0.8, 0.0),

              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: OutlinedButton.icon(onPressed: () {
                  query = "My WatchList";
                  showWatchList = true;
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ListScreen(query, showWatchList)));
                },
                icon: Opacity(child: Icon(OMDbcons.empty_heart, color: orange,), opacity: 0.5,),
                label: Text(
                    "My Watchlist",
                    style: TextStyle(
                      color: grey
                    ),
                ),

                style: ButtonStyle(
                  side: MaterialStateProperty.all(BorderSide(color: orange, width: 1.5, style: BorderStyle.solid)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))


                ),
            ),
              )),

            Align(
              alignment: Alignment(-0.7, 0.0),

              child: Text(
                  "Search the OMDb database",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
              ),
            ),

            Align(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints.tightFor(height: Scale.blockScreenHeight * 7.5),
                  child: TextField(
                    controller: queryController,
                      textInputAction: TextInputAction.go,
                    decoration: InputDecoration(
                      fillColor: grey.withOpacity(0.25),
                      filled: true,
                      focusedBorder:OutlineInputBorder(
                          borderSide: BorderSide(color: orange, width: 2.0),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent, width: 0.0),
                          borderRadius: BorderRadius.circular(15.0)
                      ),
                      hintText: "Enter movie or series name"
                    ),
                    onSubmitted: (String value){
                      query = queryController.text;
                      showWatchList = false;
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ListScreen(query, showWatchList)));
                    },
                  ),
                ),
              ),
            ),

            ConstrainedBox(
              constraints: BoxConstraints.tightFor( height: Scale.blockScreenHeight * 7.5),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: ElevatedButton(
                    onPressed: () {
                      showWatchList = false;
                      query = queryController.text;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListScreen(query, showWatchList)),
                      );
                    },
                    child: Text("Search"),
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all<Color>(orange),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(color: Colors.orange)
                          )
                      )
                    ),
                ),
              ),
            )

          ],
        ),
      )

    );
  }
}


// List screen shows search results.
class ListScreen extends StatefulWidget {
  @override
  String query = "";
  bool showWatchList = false;
  ListScreen(String input, bool watchList){
    query = input;
    showWatchList = watchList;
  }
  _ListScreenState createState() => _ListScreenState(query, showWatchList);
}

class _ListScreenState extends State<ListScreen> {
  String selectedMovie = "";
  String query = "";
  bool showWatchList = false;
  late Future<List<Thumbnail>> futureThumbnail;
  //Constructor for passing data
  _ListScreenState(String input, bool watchList){
    query = input;
    showWatchList = watchList;
  }
  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    futureThumbnail = fetchThumbnail(query, showWatchList);
  }

  Opacity ReturnThumbnailHeart(String id){
    if(WatchData.watchList.contains(id)){
      return Opacity(child: Icon(OMDbcons.heart, size: 15, color: orange,), opacity: 1.0);
    }
    else{
      return Opacity(child: Icon(OMDbcons.heart, size: 15,), opacity: 0.0);
    }
  }

  @override
  Widget build(BuildContext context){
    return(Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.black
        ),
        title: Text(
          query,
          style: TextStyle(
            color: Colors.black,

          ),
        ),
        backgroundColor: orange,
      ),
      body: FutureBuilder<List<Thumbnail>>(
        future: futureThumbnail,
        builder: (context, snapshot){
          if(snapshot.hasData){
            if(snapshot.data!.length == 0){
              if(showWatchList){
                return Center(
                    child: Text("Your watchlist is empty! Try adding some stuff.")
                );
              }
              else {
                return Center(
                    child: Text("No Results Found For \"${query}\"")
                );
              }
            }
            else {
              return GridView.builder(
                // Layout of thumbnails.
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    childAspectRatio: 2 / 3.7,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 40),

                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Wrap(
                    children: [
                      GestureDetector(
                        onTap: () {
                          selectedMovie = snapshot.data![index].id;

                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) =>
                                  DetailScreen(
                                      selectedMovie, showWatchList, query)));
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0)),
                          child: Wrap(
                            // Thumbnail styling/content.
                              children: [
                                Align(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15.0),
                                      child: Image.network(
                                        snapshot.data![index].poster,

                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(
                                          snapshot.data![index].title,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 0, 0, 10),
                                      child: Row(
                                        children: [
                                          Text(snapshot.data![index].year),
                                          ReturnThumbnailHeart(
                                              snapshot.data![index].id)
                                        ],
                                      ),
                                    )
                                  ],
                                )
                              ]

                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          }
          else if(snapshot.hasError){
            return Text("${snapshot.error}");
          }
          else{
            return Center(child: CircularProgressIndicator(color: orange));
          }
        },
      ),

    )
    );
  }
}

// Details screen for movie/series detail page.
class DetailScreen extends StatefulWidget {
  static bool isOnWatchList = false;
  void toggleWatch(){
    isOnWatchList = true;
  }
  void unToggleWatch(){
    isOnWatchList = false;
  }
  String selectedMovie = "";
  String query = "";

  @override
  _DetailScreenState createState() => _DetailScreenState(selectedMovie, isOnWatchList, query);

  DetailScreen(String input, bool watchList, String queryInput){
    selectedMovie = input;
    isOnWatchList = watchList;
    query = queryInput;
  }
}

class _DetailScreenState extends State<DetailScreen> {
  Color faveColour = grey;
  static bool isOnWatchList = false;
  String query = "";
  String selectedMovie = "";
  List<String> trailerDetails = [];
  late Future<Movie> futureMovie;
  _DetailScreenState(String input, bool watchBool, String queryInput){
    selectedMovie = input;
    isOnWatchList = watchBool;
    query = queryInput;
  }

  ShaderMask calcStar(double amount){
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (Rect rect) {
        return LinearGradient(
          stops: [0, amount, amount],
          colors: [yellow, yellow, yellow.withOpacity(0)],
        ).createShader(rect);
      },
      child: SizedBox(
        width: 25,
        height: 25,
        child: Icon(OMDbcons.star, size: 20, color: Colors.grey[300]),
      ),
    );
  }

  Row ReturnStars(String IMDBrating){
    double rating = double.parse(IMDBrating);
    rating /= 2;
    List<double> stars = [0,0,0,0,0];



    // Foreach star, calculate fill amount.
    for(int i = 0; i < 4; i++){
      if(rating > 1){
        stars[i] = 1.0;
        rating -=1;
      }
      else if(rating > 0){
        stars[i] = rating;
        rating = 0;
      }
      else{
        stars[i] = 0;
      }
    }

    return Row(
      children: [
        calcStar(stars[0]),
        calcStar(stars[1]),
        calcStar(stars[2]),
        calcStar(stars[3]),
        calcStar(stars[4])
      ],
    );
  }

  CircleAvatar ReturnHeart(String id){
    if(WatchData.watchList.contains(id)){
      faveColour = orange;
    }
    else{
      faveColour = grey;
    }
    return CircleAvatar(
        backgroundColor: faveColour.withOpacity(0.25),
        radius: 30,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
            child: Icon(OMDbcons.heart, color: faveColour)
        )
    );
  }
  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    futureMovie = fetchMovie(selectedMovie);
  }

  @override
  Widget build(BuildContext context) {
    Scale(context);
    return WillPopScope(
      onWillPop: () async{
        Navigator.pop(context);
        Navigator.pop(context);
        if(isOnWatchList){
          Navigator.push(context, MaterialPageRoute(builder: (context) => ListScreen("My WatchList", true)));
        }
        else{
          Navigator.push(context, MaterialPageRoute(builder: (context) => ListScreen(query, false)));
        }

        return false;
      },
      child: Scaffold(
        body: FutureBuilder<Movie>(
          future: futureMovie,
          builder: (context, snapshot){
            if(snapshot.hasData){
              trailerDetails = [snapshot.data!.title, snapshot.data!.type, snapshot.data!.released];
              return Column(
                children: [
                  ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.transparent],
                      ).createShader(Rect.fromLTRB(0, rect.height/3, rect.width, rect.height/1));
                    },
                    blendMode: BlendMode.dstIn,
                    child: Container(
                      // Scale the image to take up 35% of the screen.
                      height: Scale.blockScreenHeight * 35,
                      width: Scale.blockScreenWidth * 100,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fitWidth,
                          alignment: FractionalOffset.topCenter,
                          image: NetworkImage(snapshot.data!.poster),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: Scale.blockScreenHeight * 55,
                    width: Scale.blockScreenWidth * 100,
                    child: ListView(
                      children: [
                        ListTile(
                          title: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                            child: Text(
                                snapshot.data!.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 35.0,
                                ),
                            ),
                          ),
                          trailing: GestureDetector(
                              child: ReturnHeart(snapshot.data!.id),
                              onTap: (){
                                setState(() {
                                  if (faveColour == orange) {
                                    faveColour = grey;
                                  }
                                  else {
                                    faveColour = orange;
                                  }
                                });

                                if(!WatchData.isOnWatchList(snapshot.data!.id)){
                                  WatchData.watchList.add(snapshot.data!.id);

                                }
                                else{
                                  WatchData.watchList.remove(snapshot.data!.id);

                                }
                                DatabaseFunctions().SaveMovies(WatchData.watchList);
                              },
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                  "${snapshot.data!.released}, ${snapshot.data!.type[0].toUpperCase() + snapshot.data!.type.substring(1)}",
                                      style: TextStyle(
                                        color: grey,
                                        fontSize: 16.0
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: Container(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                                    child: Center(
                                      child: Text(
                                          snapshot.data!.rated,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: white,
                                            fontWeight: FontWeight.bold,

                                          ),
                                      ),
                                    ),
                                  ),
                                  decoration: new BoxDecoration(
                                  color: orange,
                                  borderRadius:
                                  new BorderRadius.all(Radius.elliptical(45,45))
                                  )
                                ),
                              )
                            ],
                          ),
                        ),
                        ListTile(
                          title: Row(
                            children: [
                              Text(
                                snapshot.data!.runtime,
                                style: TextStyle(
                                  color: grey
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: ReturnStars(snapshot.data!.rating),
                              )
                            ],
                          ),
                        ),
                        Divider(thickness: 2),
                        ListTile(
                          minLeadingWidth: 70,
                          title: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                            child: Text(
                              "Cast",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black,
                                        offset: Offset(0, -5))
                                  ],
                                  color: Colors.transparent,
                                decoration: TextDecoration.underline,
                                decorationColor: orange,
                                decorationThickness: 3
                              ),
                            ),
                          ),
                          subtitle: Text(
                              snapshot.data!.cast,
                            style: TextStyle(
                                color: grey,
                                fontSize : 16.0
                            ),
                          ),
                        ),
                        Divider(thickness: 2,),
                        ListTile(title: Text(
                                      snapshot.data!.synopsis,
                                      style: TextStyle(
                                        fontSize: 20
                                      ),
                                )
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: Scale.blockScreenHeight * 10,
                    width: Scale.blockScreenWidth * 65,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => WebviewTrailer(trailerDetails)));
                      },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(orange),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(color: orange)
                            )
                          )
                        ),
                        child: Text(
                            "Watch Trailer",
                             style: TextStyle(
                               color: white,
                               fontWeight: FontWeight.bold,
                               fontSize: 20
                             )
                        ),
                      ),
                    ),
                  )
                ],
              );
            }
            else if(snapshot.hasError){
              return Text("${snapshot.error}");
            }
            else{
              return Center(child: CircularProgressIndicator(color: orange));
            }
          }
        ),
      floatingActionButton: CircleAvatar(backgroundColor: grey.withOpacity(0.5), radius: 25,
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
            Navigator.pop(context);
            if(isOnWatchList){
              Navigator.push(context, MaterialPageRoute(builder: (context) => ListScreen("My WatchList", true)));
            }
            else{
              Navigator.push(context, MaterialPageRoute(builder: (context) => ListScreen(query, false)));
            }
          },
          child: Icon(OMDbcons.back_button, color: Colors.black,),


        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      ),
    );
  }
}

// Trailer webview screen.
class WebviewTrailer extends StatefulWidget{
  List<String> trailer = [];
  WebviewTrailer(List<String> input){
    trailer = input;
  }

  @override
  _WebviwTrailerState createState() => _WebviwTrailerState(trailer);
}

class _WebviwTrailerState extends State<WebviewTrailer> {
  List<String> trailerDetails = [""];
  _WebviwTrailerState(List<String> input){
    trailerDetails = input;
  }

  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;

  String url = "";

  double progress = 0;

  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: orange,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: Row(
            children: [Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(child: Icon(OMDbcons.back_button, color: Colors.black, size: 20,)),


              ),
            ),
              Center(child: Text("${trailerDetails[0]} Trailers", style: TextStyle(color: Colors.black))),
            ],
          ),backgroundColor: orange), backgroundColor: orange,
          body: SafeArea(
              child: Column(children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search)
                  ),
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  onSubmitted: (value) {
                    var url = Uri.parse(value);
                    if (url.scheme.isEmpty) {
                      url = Uri.parse("https://www.google.com/search?q=" + value);
                    }
                    webViewController?.loadUrl(
                        urlRequest: URLRequest(url: url));
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      InAppWebView(
                        key: webViewKey,
                        initialUrlRequest:
                        URLRequest(url: Uri.parse("https://www.youtube.com/results?search_query=${trailerDetails[0]}+${trailerDetails[1]}+${trailerDetails[2]}+trailer")),
                        initialOptions: options,
                        pullToRefreshController: pullToRefreshController,
                        onWebViewCreated: (controller) {
                          webViewController = controller;
                        },
                        onLoadStart: (controller, url) {
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        androidOnPermissionRequest: (controller, origin, resources) async {
                          return PermissionRequestResponse(
                              resources: resources,
                              action: PermissionRequestResponseAction.GRANT);
                        },
                        shouldOverrideUrlLoading: (controller, navigationAction) async {
                          var uri = navigationAction.request.url!;

                          if (![ "http", "https", "file", "chrome",
                            "data", "javascript", "about"].contains(uri.scheme)) {
                            if (await canLaunch(url)) {
                              // Launch the App
                              await launch(
                                url,
                              );
                              // and cancel the request
                              return NavigationActionPolicy.CANCEL;
                            }
                          }

                          return NavigationActionPolicy.ALLOW;
                        },
                        onLoadStop: (controller, url) async {
                          pullToRefreshController.endRefreshing();
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onLoadError: (controller, url, code, message) {
                          pullToRefreshController.endRefreshing();
                        },
                        onProgressChanged: (controller, progress) {
                          if (progress == 100) {
                            pullToRefreshController.endRefreshing();
                          }
                          setState(() {
                            this.progress = progress / 100;
                            urlController.text = this.url;
                          });
                        },
                        onUpdateVisitedHistory: (controller, url, androidIsReload) {
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onConsoleMessage: (controller, consoleMessage) {
                          print(consoleMessage);
                        },
                      ),
                      progress < 1.0
                          ? LinearProgressIndicator(value: progress)
                          : Container(),
                    ],
                  ),
                ),
              ]))),
    );
  }
}

// Thumbnail album class, uses OMDBb api to retrieve json outputs and make them more manageable.
class Thumbnail {
  final String title;
  final String year;
  final String poster;
  final String id;

  Thumbnail({required this.title, required this.year, required this.poster, required this.id});

  factory Thumbnail.fromJson(Map<String, dynamic> json){
    return Thumbnail(title: json["Title"], year: json["Year"], poster: json["Poster"], id: json["imdbID"]);

  }
}

// Movie album class, uses OMDBb api to retrieve json outputs and make them more manageable.
class Movie {
  final String title;
  final String released;
  final String rated;
  final String runtime;
  final String rating;
  final String cast;
  final String synopsis;
  final String poster;
  final String type;
  final String id;

  Movie({required this.id, required this.type, required this.title, required this.released, required this.rated, required this.runtime, required this.rating, required this.cast, required this.synopsis, required this.poster});

  factory Movie.fromJson(Map<String, dynamic> json){
    return Movie(id: json["imdbID"], type: json["Type"], title: json["Title"], released: json["Released"], rated: json["Rated"], runtime: json["Runtime"], rating: json["imdbRating"], cast: json["Actors"], synopsis: json["Plot"], poster: json["Poster"]);

  }
}

// Fetch a search of movies.
Future<List<Thumbnail>> fetchThumbnail(String search, bool showWatchList) async {
  //Branch depending on watch list of a search query.
  if(showWatchList){
    List<Thumbnail> watchList = [];
    for(int i = 0; i < WatchData.watchList.length; i++){
      final response = await http.get(Uri.parse("http://www.omdbapi.com/?i=${WatchData.watchList[i]}&apikey=cb17d26d"));
      watchList.add(Thumbnail.fromJson(jsonDecode(response.body)));
    }
    return watchList;
  }
  else{
    final response = await http.get(Uri.parse("http://www.omdbapi.com/?s=${search}&apikey=cb17d26d"));

    //Check server doesn't return an error, ie: 404/other
    if(response.statusCode == 200){
      //Json response uses keys
      Map<String, dynamic> map = jsonDecode(response.body);
      if(map["Response"] == "False"){
        List<Thumbnail> result = [];
        return result;
      }
      else{
        List thumbnailList = map["Search"];
        return thumbnailList.map((data)=>Thumbnail.fromJson(data)).toList();
      }
    }
    else{
      throw Exception("Failed to retrieve record");
    }
  }
}

// Fetch a single movie in greater detail.
Future<Movie> fetchMovie(String id) async {
  final response = await http.get(Uri.parse("http://www.omdbapi.com/?i=${id}&apikey=cb17d26d"));

  if(response.statusCode == 200){
    return Movie.fromJson(jsonDecode(response.body));
  }
  else{
    throw Exception("Failed to retrieve record");
  }
}