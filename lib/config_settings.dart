/*
      Handle reading and writing of configuration settings.
 */

import 'package:shared_preferences/shared_preferences.dart';

class ConfigSettings  {

  // settings with defaults
  Map _configSettings = {
    'sortByDist': false,              // auto sort by distance from device on/off
    "autoSortUpdate": false,          // re-sort on timer on/off
    "updateSortFreq" : 120,           // re-sort timer interval
    "autoAvailableUpdate" : false,    // auto update available on/off
    "updateAvailableFreq" : 300,      // auto update interval
    "regionFilter" : []               // only list regions in filter (null if no filter)
  };

  late SharedPreferences _prefs;


  // save a single setting of _configSettings
  void _writeSetting(key) async {

    // bool
    if (_configSettings[key] is bool) {
      _prefs.setBool(key, _configSettings[key]);

      // int
    } else if( _configSettings[key] is int) {
      _prefs.setInt(key, _configSettings[key]);

      // List
    } else if (_configSettings[key] is List) {
      _prefs.setStringList(key, _configSettings[key]);

    } // if

  }

  // retrieve a single setting of _configSettings
  void _readSetting(key)  {

    // bool
    if (_configSettings[key] is bool) {
      _configSettings[key] = _prefs.getBool(key) ?? _configSettings[key];

      // int
    } else if( _configSettings[key] is int) {
      _configSettings[key] = _prefs.getInt(key) ?? _configSettings[key];

      // List
    } else if (_configSettings[key] is List) {

      // allow null value instead of empty list
      _configSettings[key] = _prefs.getStringList(key);

    } // if

  }

  // save all config settings
  void _saveConfig()
  {
    _configSettings.forEach((k, v) {
      _writeSetting(k);
    });
  }

  // _setConfigVal
  //
  // Set value in memory and write to prefs
  //
  void _setConfigVal(key, val) {
    _configSettings[key] = val;
    _writeSetting(key);
  }

  // Getters and setters for config settings

  set regionFilter(List<String>filter) {_setConfigVal('regionFilter', filter);}
  List<String> get regionFilter { return _configSettings['regionFilter'] ?? []; }

  set sortByDist(bool val) {_setConfigVal('sortByDist', val);}
  bool get sortByDist { return _configSettings['sortByDist']; }

  set autoSortUpdate(bool val) {_setConfigVal('autoSortUpdate', val);}
  bool get autoSortUpdate { return _configSettings['autoSortUpdate']; }

  set updateSortFreq(int val) {_setConfigVal('updateSortFreq', val);}
  int get updateSortFreq { return _configSettings['updateSortFreq']; }

  set autoAvailableUpdate(bool val) {_setConfigVal('autoAvailableUpdate', val);}
  bool get autoAvailableUpdate { return _configSettings['autoAvailableUpdate']; }

  set updateAvailableFreq(int val) {_setConfigVal('updateAvailableFreq', val);}
  int get updateAvailableFreq { return _configSettings['updateAvailableFreq']; }

  ConfigSettings(SharedPreferences? prefs)
  {
    if( prefs != null)
    {
      // save shared prefs
      _prefs = prefs;

      // read all config settings
      _configSettings.forEach((k,v) => _readSetting(k));

    }
  }


}

