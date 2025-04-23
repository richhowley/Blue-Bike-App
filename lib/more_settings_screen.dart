/*

    More Settings section of settings screen

 */

import 'package:blue_bikes/services.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';

import 'config_settings.dart';
import 'filtered_stations.dart';

//ignore: must_be_immutable
class MoreSettingsScreen extends StatefulWidget {
  ConfigSettings config = ConfigSettings(null);

  MoreSettingsScreen(config) {
    this.config = config;
  }

  @override
  _MoreSettingsScreenState createState() =>
      _MoreSettingsScreenState(this.config);
}

//  Second page of settings
//  Sort based on device distance to bike stations
//  and update availabe bike and dock counts on timer
//
class _MoreSettingsScreenState extends State<MoreSettingsScreen> {
  ConfigSettings _config = ConfigSettings(null);

  _MoreSettingsScreenState(config) {
    _config = config;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: getLocationService(context),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          return Column(
            children: <Widget>[

              // settings for sorting by device distance to bike stations
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.black38),
                  borderRadius:
                      const BorderRadius.all(const Radius.circular(8)),
                  color: Colors.white,
                ),
                child: Column(
                    // header
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Bike Station Sort By Distance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 18.0,
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                      Row(children: <Widget>[
                        Expanded(
                          // sort by distance on/off
                          child: SwitchListTile(
                              title: const Text('Sort by distance'),
                              value: _config.sortByDist,
                              activeColor: Colors.blue,
                              onChanged: (snapshot.hasData && snapshot.data!)
                                  ? (bool value) {
                                      setState(() {
                                        // set value in config
                                        _config.sortByDist = value;

                                        // if turning off sort by dist also turn off auto update
                                        if (_config.sortByDist)
                                          _config.autoSortUpdate = false;

                                        // sort list based on switch
                                        Provider.of<FilteredStations>(context,
                                                listen: false)
                                                  .sortBikeList(context, value,
                                                    quiet: false);
                                      });
                                    }
                                  : null),
                        ),
                        // manual sort button

                        // re-sort list based on distance
                        TextButton(
                          //disabledTextColor: Colors.black
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.blue,
                            disabledForegroundColor: Colors.grey,
                            padding: EdgeInsets.all(8.0),
                            textStyle: TextStyle(
                              color: Colors.white,

                              )
                          ),

                          onPressed: (_config.sortByDist &&
                                  snapshot.hasData )// && snapshot.data!)
                              ? () {
                                  Provider.of<FilteredStations>(context,
                                          listen: false)
                                      .sortBikeList(context, true);
                                }
                              : null,
                          child: Text(
                            "Update Now",
                            style: TextStyle(fontSize: 15.0),
                          ),
                        ),
                      ]),
                      Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                // auto sort update on/off
                                child: SwitchListTile(
                                    activeColor: Colors.blue,
                                    title: const Text('Auto Update'),
                                    value:_config.autoSortUpdate,
                                    onChanged: (_config.sortByDist &&
                                            snapshot.hasData )// && snapshot.data!)
                                        ? (bool val) {
                                            setState(() {
                                              _config.autoSortUpdate = val;
                                            });
                                          }
                                        : null),
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              // how often bike stations are sorted by distance
                              Expanded(
                                  child: Text(
                                _config.updateSortFreq == 60
                                    ? 'Update every minute'
                                    : 'Update every ${(_config.updateSortFreq / 60).toStringAsFixed(0)} minutes',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: _config.autoSortUpdate
                                        ? Colors.black
                                        : Colors.grey,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.normal),
                              )
                              ),
                            ],
                          ),

                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Visibility(
                                  visible: _config.autoSortUpdate,
                                  child: NumberPicker(
                                      value:  _config.updateSortFreq ~/ 60,
                                      minValue: 1,
                                      maxValue: 5,
                                      axis: Axis.horizontal,
                                      onChanged:
                                          (value) {
                                        setState(() {

                                          // set update frequency slected
                                          _config.updateSortFreq = value * 60;
                                        });
                                      }
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ]
                ),
              ),

              // settings for auto updating available bikes and docks
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.black38),
                  borderRadius:
                  const BorderRadius.all(const Radius.circular(8)),
                  color: Colors.white,
                ),
                child: Column(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Update Avaialable Bikes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.0,
                          fontWeight: FontWeight.normal),
                    ),
                  ),
                  Row(children: <Widget>[
                    Expanded(
                      // auto update available  on/off
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SwitchListTile(
                            activeColor: Colors.blue,
                            title: const Text(
                                'Auto Update Available Bikes and Docks'),
                            value: _config.autoAvailableUpdate,
                            onChanged: (snapshot.hasData )// && snapshot.data!)
                                ? (bool val) {
                              setState(() {
                                _config.autoAvailableUpdate = val;
                              });
                            }
                                : null),
                      ),
                    ),
                  ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Visibility(
                          visible: _config.autoAvailableUpdate,
                          child: NumberPicker(
                              value:  _config.updateAvailableFreq ~/ 60,
                              minValue: 1,
                              maxValue: 5,
                              axis: Axis.horizontal,
                              onChanged:
                                  (value) {
                                setState(() {

                                  // set update frequency slected
                                  _config.updateAvailableFreq = value * 60;
                                });
                              }
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      // how often available bikes and docks are updated
                      Expanded(
                          child: Text(
                            _config.updateAvailableFreq == 60
                                ? 'Update every minute'
                                : 'Update every ${(_config.updateAvailableFreq / 60).toStringAsFixed(0)} minutes',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _config.autoAvailableUpdate
                                    ? Colors.black
                                    : Colors.grey,
                                fontSize: 18.0,
                                fontWeight: FontWeight.normal),
                          )),
                    ],
                  ),

                ]
                ),
              ),
            ],
          );
        });
  }
}
