/*

    Interface for Settings screen.

 */

import 'package:blue_bikes/config_settings.dart';
import 'package:blue_bikes/region_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'more_settings_screen.dart';

class MoreSettings extends StatelessWidget {
  ConfigSettings _config;

  MoreSettings(ConfigSettings config) {
    this._config = config;
  }

  @override
  Widget build(BuildContext context) {
    // More Settings
    return Scaffold(
        appBar: AppBar(
          title: Text('More Settings'),
        ),
        body: SingleChildScrollView(
            child: MoreSettingsScreen(_config)
        )
    );
  }

}

class Settings extends StatelessWidget {
  ConfigSettings _config;

  Settings(ConfigSettings config) {
    this._config = config;
  }

  @override
  Widget build(BuildContext context) {
    // regions with checkboxes and More Settings button
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: RegionList(_config),
            ),
            FlatButton(
              color: Colors.blue,
              textColor: Colors.white,
              disabledColor: Colors.grey,
              disabledTextColor: Colors.black,
              padding: EdgeInsets.all(8.0),
              splashColor: Colors.blueAccent,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MoreSettings(_config))),
              // more settings
              child: Text(
                "More Settings",
                style: TextStyle(fontSize: 16.0),
              ),
            ),
            //  _distSettings
          ],
        ));
  }
}
