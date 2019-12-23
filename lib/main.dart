import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';

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
  List _fullBikeList;
  List _regionsFilter = null;
  List bikeList;

  // initialize list, call as soon
  // as we have the list of bluebikes
  void initBikeList(List bl) {
    _fullBikeList = List.from(bl);
    bikeList = _fullBikeList;
  }

  void _filterBikes() {
    bikeList = _fullBikeList.where((f) =>
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


  // sortBikeList
  //
  // Call to sort list of bikes, pass true to
  // sort based on distance from device
  void sortBikeList(bool sortByDist) {

    // sort full list
    if( sortByDist ) {
      print("*** distance ***");
      final Distance distance = new Distance();
      LatLng loc = new LatLng(42.339661, -71.121618);
      LatLng loca = new LatLng(42.365642, -71.128071);
      LatLng locb = new LatLng(42.376114, -71.101785);

      // sort by distance
      _fullBikeList.sort((a, b) => distance(loc, new LatLng(a['lat'], a['lon'])).compareTo(distance(loc, new LatLng(b['lat'], b['lon']))));

    } else {

      // sort by alpha
      _fullBikeList.sort((a, b) => a['name'].compareTo(b['name']));

    } // else

    // filter if necessary
    if( _regionsFilter != null ) _filterBikes();

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


Set _validRegions = Set();           // regions with bikes
List _systemStatus;                 // real-time station status
Map _availableBikes = Map();        // available bike count keyed by station id
bool _sortByDist = false;

class SortByDist extends StatefulWidget {
  const SortByDist({ Key key }) : super(key: key);

  @override
  _SortByDistState createState() => _SortByDistState();
}

class _SortByDistState extends State<SortByDist> {
  @override
  Widget build(BuildContext context) {
    return
      SwitchListTile(
          title: const Text('Sort by distance'),
          value: _sortByDist,
          onChanged: (bool value) {
            setState(()
            {
                _sortByDist = !_sortByDist;

                // sort list based on switch
                Provider.of<FilteredStations>(context, listen: false).
                sortBikeList(_sortByDist);

            });
          }
      );

  }
}

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
                    ),

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
                          fontSize: 18.0, color:Colors.indigo,
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

      // strip region ids out of active list
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
              title: Text(
                region['name'],
                style: _biggerFont,
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

  // _filterRegions
  //
  // Present screen allowing filtering
  // of bike list based on region
  //
  void _filterRegions() {

    final RegionList _regionPicker = RegionList();
    final SortByDist _distSort = SortByDist();

    Navigator.of(context).push(

      MaterialPageRoute<void>(

          builder: (BuildContext context) {
            //  return _regionPicker;

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

                        _distSort

                      ],
                    )

                );
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
  Future<List> getStations(BuildContext context) async {

    List _feeds;                // data feeds for Blue Bike system
    List stations = null;  // list of stations
    List _systemRegions;        // all region

    String url;

    // https://github.com/NABSA/gbfs/blob/master/systems.csv
    String boston = 'https://gbfs.bluebikes.com/gbfs/gbfs.json';
    String houston = 'https://gbfs.bcycle.com/bcycle_houston/gbfs.json';
    String philadelphia = 'https://gbfs.bcycle.com/bcycle_indego/gbfs.json';
    String indianapolis = 'https://gbfs.bcycle.com/bcycle_pacersbikeshare/gbfs.json';
    String washingtondc = 'https://gbfs.uber.com/v1/dcb/gbfs.json';
    String losangeles = 'https://gbfs.uber.com/v1/laxb/gbfs.json';
    String austin = 'https://gbfs.uber.com/v1/atxb/gbfs.json';
    String sanantonio = 'https://gbfs.bcycle.com/bcycle_sanantonio/gbfs.json';
    String lyftChicago = 'https://s3.amazonaws.com/lyft-lastmile-production-iad/lbs/chi/gbfs.json';

    url = boston;

    // get system information feeds
    final Response feedData = await fetchInfo(url);
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

      List _bikeStationList;       // list of Blue Bike stations

      // we have data, create list of stations
      _bikeStationList =  new List.from(stationData.data['data']['stations']);

      // put all stations on filterable list
      Provider.of<FilteredStations>(context, listen: false).initBikeList(_bikeStationList);

      // sort list by alpha
      Provider.of<FilteredStations>(context, listen: false).
      sortBikeList(false);

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
              IconButton(icon: Icon(Icons.list), onPressed:_validRegions.length == 0  ? null : _filterRegions),
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