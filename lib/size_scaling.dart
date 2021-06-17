import 'package:flutter/widgets.dart';

//Scale UI elements according screen size.
//Allows all elements to be sized as a percentage of screen space.
class Scale{
  static var deviceSpecs;
  //Screen size variables (raw and split into blocks)
  static var rawScreenWidth;
  static var rawScreenHeight;
  static var blockScreenWidth;
  static var blockScreenHeight;

  //Initialise scale with screen dimensions.
  Scale(BuildContext context){
    deviceSpecs = MediaQuery.of(context);

    rawScreenWidth = deviceSpecs.size.width;
    rawScreenHeight = deviceSpecs.size.height;
    blockScreenWidth = rawScreenWidth / 100.0;
    blockScreenHeight = rawScreenHeight / 100.0;
  }
}