/*
    Store info on all regions in system.

    Setter is called after regions have been read from
    server. Only regions with bike stations are passed in.

    A color code is assigned to each region.

 */


/*
  Maintain a list of regions by id, marked as active if not filtered out.
 */


import 'package:flutter/cupertino.dart';

class SystemRegions with ChangeNotifier {

  Set _regions = Set();         // regions with bikes
  Map _colorCodes = Map();      // color codes for regions

  // getter
  get regions {
    return _regions;
  }

  // setter - call when regions are read at startup, will
  // assign a color code to each region
  set regions(regions) {

    // record passed regions
    _regions = regions;

    double _wheel = 0;  // degrees on color wheel

    // set color codes
    _regions.toList().asMap().forEach((index, region) {

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
      _colorCodes[region['region_id'].toString()] = HSLColor.fromAHSL(1.0, _hue , 0.5, 0.5).toColor();

    });

  }

  // return color code for region
  Color getColorCode(station)
  {
    return _colorCodes[station];
  }

}