
/*

    Region filter section of settings screen.

 */


import 'package:blue_bikes/system_regions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config_settings.dart';
import 'filtered_stations.dart';

class RegionList extends StatefulWidget {

  ConfigSettings config;
  RegionList(config) { this.config = config; }

  @override
  _RegionListState createState() => _RegionListState(this.config);
}

class _RegionListState extends State<RegionList>
{
  ConfigSettings _config;

  _RegionListState(config) { _config = config; }

  // setRegionFilter
  //
  // Call when selected regions are changed
  //
  List _setRegionFilter() {

    // ids of active regions
    List _regionFilter = List<String>();

    // add id of each active valid region to filter
    Provider.of<SystemRegions>(context, listen: false).regions.forEach((region) {
      if( region['active']) _regionFilter.add(region['region_id']);
    });

    // update region filter in config
    _config.regionFilter = _regionFilter;

    return(_regionFilter);

  }


  Widget build(BuildContext context) {
    final TextStyle _biggerFont = const TextStyle(fontSize: 18.0);

    // get regions
    Set regions = Provider.of<SystemRegions>(context, listen: false).regions;

    // region name with checkbox
    Iterable<CheckboxListTile> regionTiles = regions.map(
          (region) {
        return CheckboxListTile(
            title: Container(
              decoration: BoxDecoration(
                // color code
                border: Border(
                    left: BorderSide( //                   <--- left side
                      color:  Provider.of<SystemRegions>(context, listen: false).getColorCode(region['region_id']),
                      width: 5.0,
                    )
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left:8.0),
                // region name
                child: Text(
                  region['name'],
                  style: _biggerFont,
                ),
              ),
            ),
            // checkbox
            value: region['active'],
            onChanged:(val){
              setState(() {

                // set value in system region list
                region['active'] = val;

                // build a new filter to reflect this change
                Provider.of<FilteredStations>(context, listen: false).
                  regionsFilter = _setRegionFilter();

              });
            }
        );
      },
    );

    // region check boxes
    List<Widget> regionChecks = ListTile
        .divideTiles(
          context: context,
            tiles: regionTiles,
    )
        .toList();

    return
      // list of regions with checkboxes and all on/all off buttons
      Center(
        child: Card (
            child:
            Column (
              children: <Widget>[
                const ListTile(
                    title: Text('Select regions for bike listings',
                        style:
                        TextStyle(
                            fontSize: 18.0
                        )
                    )
                ),
                // on/off
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlineButton(
                        color: Colors.white,
                        textColor: Colors.black,
                        padding: EdgeInsets.all(8.0),
                        onPressed:  () {
                          // set all regions to on
                          regionTiles.forEach((region) => region.onChanged(true));
                        },
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                "All On",
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                            Icon(Icons.check_circle, color: Colors.green,),
                          ],
                        ),
                      ),
                    ),
                    OutlineButton(
                      color: Colors.white,
                      textColor: Colors.black,
                      padding: EdgeInsets.all(8.0),
                      splashColor: Colors.blueAccent,
                      onPressed:  () {
                        // set all regions to off
                        regionTiles.forEach((region) => region.onChanged(false));
                      },
                      child: Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              "All Off",
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                          Icon(Icons.highlight_off, color: Colors.red,),
                        ],
                      ),
                    ),
                  ],
                ),

                Expanded (
                  child: ListView(children: regionChecks),
                ),

              ],
            )
        ),
      );

  }

}
