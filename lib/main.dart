/*
      Blue Bikes

      App to display info on Bluebikes, the Bikeshare Program of
      Metro-Boston.

      All bike stations in the system are listed with available
      bikes and docks. The list can be filtered by region and
      sorted by distance from device. If desired, the list can be
      re-sorted by distance on a timer.

      Available bikes and docks can be updated manually or on a timer.

 */

import 'package:blue_bikes/filtered_stations.dart';
import 'package:blue_bikes/system_regions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bike_station_list.dart';
import 'config_settings.dart';

ConfigSettings? _config; // configuration settings stored on device

void main() {
  runApp(
    MultiProvider (
      providers: [
        // list of regions in the Blue Bike system
        ChangeNotifierProvider(create: (context) => SystemRegions()),
        // list of stations in the Blue Bike system
        ChangeNotifierProvider(create: (context) => FilteredStations()),
      ],
      child: BlueBikeApp(),
    ),
  );
}

// app home screen
class HomePage extends StatelessWidget {
  HomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  final BikeStationList homeBuilder = BikeStationList(_config) ;
  @override
  Widget build(BuildContext context) {
    return homeBuilder;

  }

}

// main widget for runApp()
class BlueBikeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blue Bikes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title:"Blue Bikes"),
    );
  }
}
