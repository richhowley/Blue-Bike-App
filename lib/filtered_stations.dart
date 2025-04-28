/*

    Handle filtering of bike stations based on region.

    Maintaion a list of filtered bike stations and available
    bikes and docks for each station.

 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';

class FilteredStations with ChangeNotifier {
  List _fullBikeList;         // complete list of installed stations read from server
  List _bikeList;             // list with filter applied
  List _regionsFilter;        // IDs of regions to display
  Map _availableBikes = Map(); // available bike count keyed by station id

  // getters
  get availableBikes  { return _availableBikes; }
  get bikeList  { return _bikeList; }

  // initialize list, call as soon
  // as we have the list of bluebikes
  void initBikeList(List bl) {

    // remove stations not on street
    _fullBikeList = bl.where((f) => _availableBikes[f['station_id']]['is_installed']== 1).toList();

    // filtered list begins with all stations
    _bikeList = _fullBikeList;
  }

  // set bikelist to only stations in selected regions
  void _filterBikes() {
    _bikeList = _fullBikeList.where((f) =>
    _regionsFilter.indexOf(f['region_id'].toString()) != (-1))
        .toList();

  }

  // use passed filter to set list of stations
  set regionsFilter(regions) {

    // save filter
    _regionsFilter = regions;

    // filter list
    _filterBikes();

    notifyListeners();
  }

  // bikeListUpdated
  //
  // Call after the full list has been sorted
  //
  void _bikeListUpdated() {

    // filter if necessary
    if( _regionsFilter != null ) _filterBikes();

    notifyListeners();

  }

  // bikeStatusUpdated
  //
  //  Call when available bike count has been updated
  //
  void bikeStatusUpdated(List _stationStatus) {

    // make a map of available bikes, key is station id
    for( var s in _stationStatus )
      _availableBikes[s['station_id']] =
      {
        'available': s['num_bikes_available'],
        'num_docks_available': s['num_docks_available'],
        'is_installed' : s['is_installed']
      };

    notifyListeners();
  }

  // sortBikesByDist
  //
  // Sort bike list by distance from device
  // Return current location of device
  //
  Future<Position> sortBikesByDist(BuildContext context, bool quitet) async {

    if( !quitet ) {

      // sorting message as modal
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: Text("Getting location ..."),
            content:
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                <Widget>[
                  CircularProgressIndicator()
                ]
            ),

          );
        },
      );

    } // if

    // get device location
    final Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if( position != null ) {
      final Distance distance = new Distance();
      final LatLng loc = new LatLng(position.latitude, position.longitude);

      // sort by distance
      _fullBikeList.sort((a, b) =>
          distance(loc, new LatLng(a['lat'], a['lon'])).compareTo(
              distance(loc, new LatLng(b['lat'], b['lon']))));

      // filter and update
      _bikeListUpdated();

      // remove modal
      if( !quitet ) Navigator.pop(context);

    } // if

    return(position);
  }

  // sortBikeList
  //
  // Call to sort list of bikes, pass true to
  // sort based on distance from device
  //
  void sortBikeList(BuildContext context, bool sortByDist, {bool quiet: true}) {

    // sort full list
    if( sortByDist ) {

      // sort by distance to device
      sortBikesByDist(context, quiet);

    } else {

      // sort by alpha
      _fullBikeList.sort((a, b) => a['name'].compareTo(b['name']));

      // filter and update
      _bikeListUpdated();

    } // else

  }

}
