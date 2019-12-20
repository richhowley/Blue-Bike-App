import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

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
  List bikeList;

  // initialize list, call as soon
  // as we have the list of bluebikes
  void initBikeList(List bl) {
    bikeList = List.from(bl);
  }

  // set filtered list and notify listners
  void setBikeList(List bl) {
    bikeList = List.from(bl);
    notifyListeners();
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

List _bikeStationList = null;       // list of Blue Bike stations
Set _validRegions = null;           // regions with bikes
List _systemStatus;                 // real-time station status
Map _availableBikes = Map();        // available bike count keyed by station id

// row for bike station list
Widget _buildBikeRow(BuildContext context, var station) {

  // Left Column
  //
  //  Bike station name
  //
  final leftColumn =
      Expanded (
          child:
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
                    )
                  ],
                ),
            )
      );

  // Right Column
  //
  // # of bikes avaialabel and # of docks available
  //
  final rightColumn =
      Padding(
        padding: const EdgeInsets.all(8.0),
          child: Column (
            children: <Widget>[
              Row (
                children: <Widget>[
                  Text(
                    _availableBikes[station['station_id']]['available'].toString(),
                    style:
                      TextStyle(
                          fontSize: 18.0, color:Colors.indigo
                      ),
                  )
                ],
              ),
              Divider(
                height: 5,
              ),
              Row (
                children: <Widget>[
                  Text(
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
          child:
              Row (
                children: <Widget>[
                  leftColumn,
                  rightColumn
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

// RegionList
//
// Handles screen for choosing regions
//

class RegionList extends StatefulWidget {
  RegionList({Key key}) : super(key: key);

    @override
    _RegionListState createState() => _RegionListState();
  }

  class _RegionListState extends State<RegionList>
  {

    // filterRegion
    //
    // Call to restrict the list of bikes to active regions
    //
    bool filterRegion(var station) {

      List regionFilter = [];

      // get list of active regions
      List regions = _validRegions.where((f) => f['active'] == true).toList();

      // strip region ids out of active list
      for(final r in regions){ regionFilter.add(r['region_id']); }

      // return true if station has a region id on the active list
      return regionFilter.indexOf(station['region_id'].toString()) != (-1);
    }

    Widget build(BuildContext context) {
      final TextStyle _biggerFont = const TextStyle(fontSize: 18.0);

      // checkbox for each region
      Iterable<CheckboxListTile> tiles = _validRegions.map(
            (region) {
          return CheckboxListTile(
              title: Text(
                region['name'],
                style: _biggerFont,
              ),
              value: region['active'],
              onChanged:(val){
                setState(() {

                  // toggle value in region list
                  region['active'] = !region['active'];

                  // filter bike station list to reflect change
                  Provider.of<FilteredStations>(context, listen: false).
                  setBikeList(_bikeStationList.where((f) => filterRegion(f))
                      .toList());

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

      return Scaffold(
          appBar: AppBar(
            title: Text("Select Regions"),
          ),
          body: ListView(children: divided),

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

  // _filterRegions
  //
  // Present screen allowing filtering
  // of bike list based on region
  //
  void _filterRegions() {

    final RegionList _regionPicker = RegionList();

    Navigator.of(context).push(

      MaterialPageRoute<void>(

          builder: (BuildContext context) {
              return _regionPicker;
          },

        )
    );
  }

  Future<List> _sList;

  // getStations
  //
  // Read information on Blue Bike system from
  // server.  Information includes data feeds
  // and region oodes,  Return list of stations.
  //
  static Future<List> getStations(BuildContext context) async {

    List _feeds;                // data feeds for Blue Bike system
    List stations = null;  // list of stations
    List _systemRegions;        // all region

    String url;

    // get system information feeds
    final Response feedData = await fetchInfo("https://gbfs.bluebikes.com/gbfs/gbfs.json");
    _feeds = new List.from(feedData.data['data']['en']['feeds']);

    // use system region url to get region codes
    url = _feeds.where((f) => f['name'] == 'system_regions').toList()[0]['url'];
    final Response regionData = await fetchInfo(url);
    _systemRegions = new List.from(regionData.data['data']['regions']);

    // get station status
    url = _feeds.where((f) => f['name'] == 'station_status').toList()[0]['url'];
    final Response statusData = await fetchInfo(url);
    _systemStatus = new List.from(statusData.data['data']['stations']);

    // make a map of available bikes, key is staton id
    for( var s in _systemStatus ) _availableBikes[s['station_id']] =
    {'available': s['num_bikes_available'], 'num_docks_available': s['num_docks_available']};

    // use system information url to get info on stations
    url = _feeds.where((f) => f['name'] == 'station_information').toList()[0]['url'];
    final Response stationData = await fetchInfo(url);

    // if call was successful
    if( stationData != null ) {

      // we have data, create list of stations
      _bikeStationList =  new List.unmodifiable(stationData.data['data']['stations']);

      // put all stations on filterable list
      Provider.of<FilteredStations>(context, listen: false).initBikeList(_bikeStationList);

      _validRegions = Set();

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
          }

        }

      }


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
    _sList = getStations(context);
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
              padding: const EdgeInsets.only(top: 16),
              child: Text('Error: ${snapshot.error}'),
            )
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

        return Scaffold(
          appBar: AppBar (
            title: Text('Blue Bikes'),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.list), onPressed:_validRegions == null ? null : _filterRegions),
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
 // final Future<List> sList = getStations();   // TESTING *****

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