/*
    All Blue Bike API calls are made here.

 */


// fetchInfo
//
// Make async call to server
//
import 'package:dio/dio.dart';

Future<Response> fetchInfo(String url) async {
  Response retVal;
  final response = await Dio().get(url);

  // if call was successful
  if (response.statusCode == 200) {

    // save data
    retVal = response;
  } else {

    // error
    retVal = null;
    throw Exception('Failed to load data');
  }

  return retVal;
}

