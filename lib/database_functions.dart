import 'package:flutter/cupertino.dart';
import 'package:omdb_app/data.dart';
import 'package:omdb_app/main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseFunctions {

  //Database functions.
  //Create database if one doesn't exist, and open.
  final database = openDatabase(
      join('omdbapp_database.db'),
      onCreate: (db, version) {
  // Run the CREATE TABLE statement on the database.
  return db.execute(
  'CREATE TABLE movies(id integer PRIMARY KEY, imdbID TEXT)',
  );
  },
      version: 1
  );

  //Insert a movie record into the database
  Future<void> SaveMovies(List<String> moviesToSave) async {
    // Get a reference to the database.
    final db = await database;

    List<SavedMovie> listToInsert = [];
    for(int i = 0; i < moviesToSave.length; i++){
      listToInsert.add(SavedMovie(imdbID: moviesToSave[i]));
    }

    await db.delete(
      'movies'
    );

    // Replace any previous data with new data in case of conflict.
    for(int i = 0; i < listToInsert.length; i++){
      await db.insert(
        'movies',
        listToInsert[i].toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> LoadMovies() async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The movies.
    final List<Map<String, dynamic>> maps = await db.query('movies');

    // Convert the List<Map<String, dynamic> into a List<Movies>.
    List listOfMovies = List.generate(maps.length, (i) {
      return SavedMovie(
        imdbID: maps[i]['imdbID'],
      );
    });

    // Convert list of Movies into a list of imdbID's
    List<String> idList = [];
    for(int i = 0; i < listOfMovies.length; i++){
      idList.add(listOfMovies[i].imdbID);
    }
    WatchData.watchList = idList;
  }
}

// Movie class for saving.
class SavedMovie{
  final String imdbID;
  SavedMovie({
    required this.imdbID
  });

  //Map function for storing records.
  Map<String, dynamic> toMap() {
    return {
      'imdbID': imdbID
    };
  }
  // For reading/debugging
  @override
  String toString() {
    return 'SavedMovie{imdbID: $imdbID}';
  }
}