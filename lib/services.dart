/*
      Chceck for OS services.
 */

// getLocationService
//
// Return true if location service is turned on
//
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

Future<bool> getLocationService(BuildContext context) async {
  bool _status;

  _status  = await Geolocator.isLocationServiceEnabled ();

  return _status;
}