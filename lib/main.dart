import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'dart:async';

List _feeds;    // urls for auto discuovery

void main() {
  runApp(
    // Provider holds a list of stations ni the Blue Bike system
    ChangeNotifierProvider(
      create: (context) => FilteredStations(),
      child: BlueBikeApp(),
    ),
  );
}

class FilteredStations with ChangeNotifier {
  List _fullBikeList;         // complete list of installed stations read from server
  List _bikeList;             // list with filter applied
  List _regionsFilter = null;
  Map _availableBikes = Map(); // available bike count keyed by station id

  // initialize list, call as soon
  // as we have the list of bluebikes
  void initBikeList(List bl) {

    // remove stations not on street
    _fullBikeList = bl.where((f) => _availableBikes[f['station_id']]['is_installed']== 1).toList();

    // filtered list begins with all stations
    _bikeList = _fullBikeList;
  }

  void _filterBikes() {
    _bikeList = _fullBikeList.where((f) =>
    _regionsFilter.indexOf(f['region_id'].toString()) != (-1))
        .toList();

  }

  // used passed filter to set list
  void setBikeListFilter(List regions) {

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
  void bikeListUpdated() {

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
  // Return current location of device
  //
  Future<Position> sortBikesByDist(BuildContext context) async {

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
                <Widget> [
                  CircularProgressIndicator()
                ]
          ),

        );
      },
    );

    final Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if( position != null ) {
      final Distance distance = new Distance();
      final LatLng loc = new LatLng(position.latitude, position.longitude);

      // sort by distance
      _fullBikeList.sort((a, b) =>
          distance(loc, new LatLng(a['lat'], a['lon'])).compareTo(
              distance(loc, new LatLng(b['lat'], b['lon']))));

      // filter and update
      bikeListUpdated();

      // remove modal
      Navigator.pop(context);

    } // if
  }

  // sortBikeList
  //
  // Call to sort list of bikes, pass true to
  // sort based on distance from device
  void sortBikeList(BuildContext context, bool sortByDist) {

    // sort full list
    if( sortByDist ) {

      // sort by distance to device
      sortBikesByDist(context);

    } else {

      // sort by alpha
      _fullBikeList.sort((a, b) => a['name'].compareTo(b['name']));

      // filter and update
      bikeListUpdated();

    } // else


  }

}

// fetchInfo
//
// Make async call to server
//
Future<Response> fetchInfo(String url) async {
  Response retVal = null;
  final response = await Dio().get(url);

  // if call was successful
  if (response.statusCode == 200) {

    // save data
    retVal = response;
  } else {

    // error
    throw Exception('Failed to load data');
  }

  return retVal;
}

Set _validRegions = Set();  // regions with bikes
bool _sortByDist = false;  // true => sort stations by distance from device

// _getLocationService
//
// Return true if location service is turned on
//
Future<bool> _getLocationService(BuildContext context) async {
  bool _status = null;
  _status  = await Geolocator().isLocationServiceEnabled ();

  return _status;
}

// Distance section of settings screen

class DistSettings extends StatefulWidget {
  const DistSettings({ Key key }) : super(key: key);

  @override
  _DistSettingsState createState() => _DistSettingsState();
}

// Switch to sort by distance and button to refresh sort
//  only enabled if location service is turn on
//
class _DistSettingsState extends State<DistSettings> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future:  _getLocationService(context),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          return Column (
              children: <Widget>[
                    Row(
                      children: <Widget>[
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Sort by distance'),
                              value: _sortByDist,
                              onChanged: (snapshot.hasData && snapshot.data) ?
                                  (bool value) {
                                    setState(() {
                                    _sortByDist = value;;

                                    // sort list based on switch
                                    Provider.of<FilteredStations>(context, listen: false).
                                    sortBikeList(context, _sortByDist);
                                    });
                                  } : null
                            ),
                          ),
                      ]
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FlatButton(
                            color: Colors.blue,
                            textColor: Colors.white,
                            disabledColor: Colors.grey,
                            disabledTextColor: Colors.black,
                            padding: EdgeInsets.all(8.0),
                            splashColor: Colors.blueAccent,
                            onPressed: (_sortByDist && snapshot.hasData && snapshot.data) ? () {
                              // re-sort list based distance
                              Provider.of<FilteredStations>(context, listen: false).
                              sortBikeList(context, true);
                            } : null,
                            child: Text(
                              "Refresh",
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                        ),
                      ],
                    )
              ]
            );

        });
  }
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
                  Text(
                    Provider.of<FilteredStations>(context, listen: false).
                    _availableBikes[station['station_id']]['available'].toString(),
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
                  Text(
                    Provider.of<FilteredStations>(context, listen: false).
                    _availableBikes[station['station_id']]['num_docks_available'].toString(),
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

      final tileLayout =
          Container (
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide( //                   <--- left side
                      color:_validRegions.where((f) => f['region_id'] ==
                          station['region_id'].toString()).toList()[0]['color'],
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

// view of bike stations, will change when list is filtered
Widget _bikeLocationsBuilder(BuildContext context) {
  return
    Consumer<FilteredStations>(
      builder: (context, filter, child) =>
          ListView.builder(
            itemCount: filter._bikeList.length,
            padding: EdgeInsets.all(16.0),
            itemBuilder: (context, i) {
              return(Card(
                  elevation: 3,
                  child:_buildBikeRow(context, filter._bikeList[i])
              )
          );
        }
      ),
  );
}

// RegionList
//
// Handles region filter section of settings screen
//

class RegionList extends StatefulWidget {
  RegionList({Key key}) : super(key: key);

    @override
    _RegionListState createState() => _RegionListState();
  }



  class _RegionListState extends State<RegionList>
  {
    List _regionFilter;

    // setRegionFilter
    //
    // Call when selected regions are changed
    //
    List setRegionFilter() {

      List _regions = [];  // active regions

      _regionFilter = [];  // ids of active regions

      // get list of active regions
      _regions = _validRegions.where((f) => f['active'] == true).toList();

      // add region ids from desired regions to filter
      for(final r in _regions){ _regionFilter.add(r['region_id']); }

      return(_regionFilter);
    }

    // filterRegion
    //
    // Call to restrict the list of bikes to active regions
    //
    bool filterRegion(var station) {

      // return true if station has a region id on the active list
      return _regionFilter.indexOf(station['region_id'].toString()) != (-1);
    }

    Widget build(BuildContext context) {
      final TextStyle _biggerFont = const TextStyle(fontSize: 18.0);

      // checkbox for each region
      Iterable<CheckboxListTile> tiles = _validRegions.map(
            (region) {
          return CheckboxListTile(
              title: Container(
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide( //                   <--- left side
                        color: region['color'],
                        width: 5.0,
                      )
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left:8.0),
                  child: Text(
                    region['name'],
                    style: _biggerFont,
                  ),
                ),
              ),
              value: region['active'],
              onChanged:(val){
                setState(() {

                  // toggle value in region list
                  region['active'] = !region['active'];

                  // build a new filter to reflect this change
                  setRegionFilter();
                  Provider.of<FilteredStations>(context, listen: false).
                  setBikeListFilter(setRegionFilter());

               });
              }
          );
        },
      );

      List<Widget> divided = ListTile
          .divideTiles(
        context: context,
        tiles: tiles,
      )
          .toList();

      return
            Center(
              child: Card (
                child:
                    Column (
                      children: <Widget>[
                        const ListTile(
                          title: Text('List only bikes in:',
                          style:
                            TextStyle(
                                fontSize: 18.0
                            )
                          ),
                        ),
                        Expanded (
                          child: ListView(children: divided),
                        ),

                      ],
                    )

              ),
            );

    }

  }

class BikeStationList extends StatefulWidget {
  BikeStationList({Key key}) : super(key: key);

  @override
  _BikeStationListState createState() => _BikeStationListState();
}

class _BikeStationListState extends State<BikeStationList>
{

  // _showSettings
  //
  // Present settings screen
  //
  void _showSettings() {

    final RegionList _regionPicker = RegionList();      // filter by region
    final DistSettings _distSettings = DistSettings();  // sort by distance

    Navigator.of(context).push(

      MaterialPageRoute<void>(
          builder: (BuildContext context) {
              return
                Scaffold(
                  appBar: AppBar(
                    title: Text('Settings'),
                  ),
                  body:
                    Column(
                      children: <Widget>[
                        Expanded (
                          child: _regionPicker,
                        ),

                        _distSettings

                      ],
                    )
                );
          },
        )
    );
  }

  // _getStationStatus
  //
  // Read real-time count of available bikes and docks
  //
  Future<void> _getStationStatus() async {

    final String url = _feeds.where((f) => f['name'] == 'station_status').toList()[0]['url'];
    final Response statusData = await fetchInfo(url);

    // update interface
    Provider.of<FilteredStations>(context, listen: false).
    bikeStatusUpdated( new List.from(statusData.data['data']['stations']));

  }

  // _updateStatus
  //
  // Call to update the count of available bikes
  // and docks
  //
  Future<void> _updateStatus(BuildContext context) async {

    // read status
    await _getStationStatus();

    // confirm update message
    final snackBar = SnackBar(content: Text('Station info updated'));
    Scaffold.of(context).showSnackBar(snackBar);

  }


  Future<List> _sList = Future.value(null);

  // getStations
  //
  // Read information on Blue Bike system from
  // server.  Information includes data feeds
  // and region oodes,  Return list of stations.
  //
  Future<List> getStations() async {

    // self discovery url for Blue Bike system
    String url = 'https://gbfs.bluebikes.com/gbfs/gbfs.json';
    List stations = null;  // list of bike stations
    List _systemRegions;   // all regions

    // get system information feeds
    final Response feedData = await fetchInfo(url);
    _feeds = new List.from(feedData.data['data']['en']['feeds']);

    // use system region url to get region codes
    url = _feeds.where((f) => f['name'] == 'system_regions').toList()[0]['url'];
    final Response regionData = await fetchInfo(url);
    _systemRegions = new List.from(regionData.data['data']['regions']);

    // get current status for each station
    await _getStationStatus();

    // use system information url to get info on stations
    url = _feeds.where((f) => f['name'] == 'station_information').toList()[0]['url'];
    final Response stationData = await fetchInfo(url);

    // if system information call was successful
    if( stationData != null ) {

      // we have data, create list of stations
      final List _bikeStationList =  new List.from(stationData.data['data']['stations']);

        // put all stations on filterable list
      Provider.of<FilteredStations>(context, listen: false).initBikeList(_bikeStationList);

      // sort list by alpha
      Provider.of<FilteredStations>(context, listen: false).
      sortBikeList(context, false);

      // make set containing only regions with bikes
      for(final region in _systemRegions){

        // look at each bike station
        for(final station in _bikeStationList ) {

          // if station ids match, add to set
          if( station['region_id'].toString() == region['region_id']) {
            _validRegions.add({'name': region['name'],
              'region_id': region['region_id'],
              "active": true});

            // stop looking
            break;

          } // if
        } // for
      } // for

      double _wheel = 0;  // degrees on color wheel

      // assign a color code to each region
      _validRegions.toList().asMap().forEach((index, region) {

        double _hue;

        // adjacent region colors are opposites on the color wheel
        if( (index%2) == 0 ) {
            _hue = _wheel;
          } else {
          // take value from opposite side on odd entries
          _hue = _wheel+180;

          // move hue around wheel
          _wheel += 35;
        }

        // set color code
        region['color'] = HSLColor.fromAHSL(1.0, _hue , 0.5, 0.5).toColor();

      });


      // set return value
      stations = _bikeStationList;

    } // if

    return(stations);

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
    return FutureBuilder<List>(
      future: _sList,
      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
        List<Widget> children;

        // if all async data has been read
        if (snapshot.hasData) {

           children = <Widget>[
            // list of bike stations
            Expanded(
              child: _bikeLocationsBuilder(context)
            ),
          ];

        } else if (snapshot.hasError) {
          children = <Widget>[
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Unalbe to read from server'),
            ),
          ];
        } else {

          // waiting for data
          children = <Widget>[
            SizedBox(
              child: CircularProgressIndicator(),
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
                    return IconButton(icon: Icon(Icons.directions_bike),
                        onPressed: snapshot.hasData
                            ? () => _updateStatus(context)
                            : null);

                  }
               ),
               IconButton(icon: Icon(Icons.list), onPressed:_validRegions.length == 0  ? null : _showSettings),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

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

class HomePage extends StatelessWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;
  final BikeStationList homeBuilder = BikeStationList();
  @override
  Widget build(BuildContext context) {
    return homeBuilder;
  }
}