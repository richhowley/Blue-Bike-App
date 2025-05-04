/*

    Home screen of app, list of available bikes and docks.

 */

import 'dart:async';
import 'package:blue_bikes/settings.dart';
import 'package:blue_bikes/system_regions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_calls.dart';
import 'config_settings.dart';
import 'filtered_stations.dart';

//ignore: must_be_immutable
class BikeStationList extends StatefulWidget {

  ConfigSettings _config = ConfigSettings(null);

  BikeStationList(ConfigSettings? config) { if( config != null ) this._config = config; }

  @override
  _BikeStationListState createState() =>
      _BikeStationListState(this._config);
}

class _BikeStationListState extends State<BikeStationList>
{
  Timer? _updateTimer;       // timer for updating available bikes/docks
  Timer? _sortTimer;         //te timer for sorting by distance from device
  List _feeds=[];              // urls for auto discovery
  ConfigSettings _config = new ConfigSettings(null);  // configureation settings stored on device

  _BikeStationListState(ConfigSettings config) { _config = config; }

  // _getStationStatus
  //
  // Read real-time count of available bikes and docks
  //
  Future<void> _getStationStatus() async {

    final String url = _feeds.where((f) => f['name'] == 'station_status').toList()[0]['url'];
    final Response? statusData = await fetchInfo(url);

    // update interface
    if( statusData != null )
    {
      Provider.of<FilteredStations>(context, listen: false).
      bikeStatusUpdated( new List.from(statusData.data['data']['stations']) );

    } // if

  }

  // _updateStatus
  //
  // Call to update the count of available bikes
  // and docks, pass quite:false for no upate message
  //
  Future<void> _updateStatus(BuildContext context, bool quiet) async {

    // read status
    await _getStationStatus();

    if( !quiet )
    {
      // confirm update message
      final snackBar = SnackBar(content: Text('Bike and dock info updated'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    } // if

  }


  Future<List> _sList = Future.value([]);

  // getStations
  //
  // Read information on Blue Bike system from
  // server.  Information includes data feeds
  // and region oodes,  Return list of stations.
  //
  Future<List> getStations() async {

    // self discovery url for Blue Bike system
    String url = 'https://gbfs.bluebikes.com/gbfs/gbfs.json';
    List _stations = [];  // list of bike stations
    List _allRegions;   // all regions

    // get system information feeds
    final Response? feedData = await fetchInfo(url);
    if( feedData == null )
    {
      _feeds = List.empty();

    } else {
      _feeds = new List.from(feedData.data['data']['en']['feeds']);

    } // else
    // use system region url to get region codes
    url = _feeds.where((f) => f['name'] == 'system_regions').toList()[0]['url'];
    final Response? regionData = await fetchInfo(url);

    if( regionData == null )
    {
      _allRegions = List.empty();

    } else {
      _allRegions = new List.from(regionData.data['data']['regions']);
    } // else

    // get current status for each station
    await _getStationStatus();

    // use system information url to get info on stations
    url = _feeds.where((f) => f['name'] == 'station_information').toList()[0]['url'];
    final Response? stationData = await fetchInfo(url);

    // if system information call was successful
    if( stationData != null ) {

      // we have data, create list of stations
      final List _bikeStationList =  new List.from(stationData.data['data']['stations']);

      // put all stations on filterable list
      Provider.of<FilteredStations>(context, listen: false).initBikeList(_bikeStationList);

      // create preferences class
      SharedPreferences _prefs = await SharedPreferences.getInstance();
      _config = ConfigSettings(_prefs);

      // sort bike list
      Provider.of<FilteredStations>(context, listen: false).
      sortBikeList(context, _config.sortByDist, quiet: false);

      // read saved region filter
      List<String> _savedRegionFilter = _config.regionFilter;

      // restore saved region filter
      Provider.of<FilteredStations>(context, listen: false).regionsFilter =
          _savedRegionFilter;

      Set _validRegions = Set();  // regions with bikes

      // make set containing only regions with bikes
      for(final region in _allRegions){

        // look at each bike station
        for(final station in _bikeStationList ) {

          // if station ids match, add to set
          // mark active if selected in preferences or a new region
          if( station['region_id'].toString() == region['region_id']) {
            _validRegions.add({'name': region['name'],
              'region_id': region['region_id'],
              "active": _savedRegionFilter == null ? true :
              _savedRegionFilter.indexOf(region['region_id']) >= 0
            });

            // stop looking
            break;

          } // if
        } // for
      } // for

      // set regions in system
      Provider.of<SystemRegions>(context, listen: false).regions = _validRegions;

      // set return value
      _stations = _bikeStationList;

    } // if

    return(_stations);

  }


  // row for bike station list
  Widget _buildBikeRow(BuildContext context, var station) {

    // Left Column
    //
    //  Bike station name
    //
    final leftColumn =
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column (
        children: <Widget>[
          // station name
          Text(
            station['name'],
            style:
            TextStyle(
                fontSize: 18.0
            ),
          ),

        ],
      ),
    );

    // Right Column
    //
    // # of bikes available and # of docks available
    //
    final rightColumn =
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column (
        children: <Widget>[
          Row (
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              // available bikes
              Text(
                Provider.of<FilteredStations>(context, listen: false).
                availableBikes[station['station_id']]['available'].toString(),
                style:
                TextStyle(
                  fontSize: 18.0, color:Colors.indigo,
                ),
              )
            ],
          ),
          Divider(
            height: 5,
          ),
          Row (
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              // available docks
              Text(
                Provider.of<FilteredStations>(context, listen: false).
                availableBikes[station['station_id']]['num_docks_available'].toString(),
                style:
                TextStyle(
                    fontSize: 18.0, color:Colors.blueGrey
                ),
              )
            ],
          ),
        ],
      ),
    );

    // tiles for each bike station
    final tileLayout =
    Container (
        decoration: BoxDecoration(
          border: Border(
            // color code
              left: BorderSide( //                   <--- left side
                color:  Provider.of<SystemRegions>(context, listen: false).getColorCode(station['region_id'].toString()),
                width: 5.0,
              )
          ),
        ),
        child:
        Row (
          children: <Widget>[
            Expanded(flex: 8, child: leftColumn),
            Expanded(flex: 2, child: rightColumn)
          ],
        )
    );


    return tileLayout;
  }

  // view of bike stations
  // will change when list is filtered or sorted or available
  // bikes and docks are updated
  Widget _bikeLocationsBuilder(BuildContext context) {
    return
      Consumer<FilteredStations>(
        builder: (context, filter, child) =>
            ListView.builder(
                itemCount: filter.bikeList.length,
                padding: EdgeInsets.all(16.0),
                itemBuilder: (context, i) {
                  return(Card(
                      elevation: 3,
                      child:_buildBikeRow(context, filter.bikeList[i])
                  )
                  );
                }
            ),
      );
  }


  @override
  void initState() {
    super.initState();

    // read data on bike system, last piece
    // of information read is list of stations
    _sList = getStations();
  }

  // Home screen is built with a FutureBuilder
  // so we can show a loading message while
  // reading from server

  Widget build(BuildContext context) {

    return
      FutureBuilder<List>(
        future: _sList ,
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          List<Widget> bikeList;

          // if all async data has been read
          if (snapshot.hasData) {

            // if we need a sort by distance timer
            if( _sortTimer == null && (_config.autoSortUpdate) )
            {
              // create timer
              _sortTimer = Timer.periodic(Duration(seconds: _config.updateSortFreq), (timer) {

                // if we still want auto upates
                if( _config.autoSortUpdate
                    && _config.sortByDist )
                {
                  // sort list based on dist
                  Provider.of<FilteredStations>(context, listen: false).
                  sortBikeList(context, _config.sortByDist);

                } else {

                  // turn off timer
                  timer.cancel();

                } // else

              });
            }

            // if we need a bike/dock available timer
            if( _updateTimer == null && (_config.autoAvailableUpdate) ) {

              // create timer
              _updateTimer = Timer.periodic(Duration(seconds:
              _config.updateAvailableFreq), (timer) {

                // if we still want auto upates
                if (_config.autoAvailableUpdate) {
                  // update available bikes and docks
                  _updateStatus((context), true);
                } else {
                  // turn off timer
                  timer.cancel();
                  _updateTimer = null;
                } // else

              });


            } // if


            bikeList = <Widget>[
              // list of bike stations
              Expanded(
                  child: _bikeLocationsBuilder(context)
              ),
            ];

          } else if (snapshot.hasError) {

            // error reading from server
            bikeList = <Widget>[
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unalbe to read from server,\n check internet connection.'),
              ),
            ];
          } else {

            // waiting for data
            bikeList = <Widget>[
              SizedBox(
                child: CircularProgressIndicator(
                  valueColor:AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                width: 60,
                height: 60,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Getting list of Blue Bikes ...'),
              )
            ];
          }

          // Homepage screen
          return Scaffold(
            appBar: AppBar (
              title: Text('Blue Bikes'),
              actions: <Widget>[
                Builder (
                    builder: (BuildContext context) {
                      // update available button
                      return IconButton(icon: Icon(Icons.directions_bike),
                          onPressed: snapshot.hasData
                              ? () => _updateStatus(context, false)
                              : null);

                    }
                ),
                IconButton(icon: Icon(Icons.list),
                  // navigate to settins page
                  onPressed: Provider.of<SystemRegions>(context, listen: false).regions == 0  ? null : ()
                  {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Settings(_config)));
                  },

                )

              ],
            ),

            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: bikeList,

              ),
            ),
          );
        },
      );
  }
}
