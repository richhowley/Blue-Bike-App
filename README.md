# Blue Bikes

A mobile application to provides information on the Boston public bike sharing system [BLUEbikes](https://www.bluebikes.com/). Since it was developed using the [Flutter UI toolkit](https://flutter.dev/) it can be built for either Android or iOS.

**Using the App**

Always know how many bikes are available for rent and how many docks are taking bike returns at each station in the BLUEbikes system. Open the app and there is a list of every bike station in the system with the number of bikes available in blue and the docks accepting bikes in grey.

Only want the bikes in your city? Click the settings button from the home screen then select only the cities to include on the home screen. Want the bike stations sorted by ditance from your device, so the closest ones are on top? From the setting screen click the More Settings button then turn on "Sort by distance". 

Turn on "Auto Update" for sorting by distance and availabe bikes on the More Settings screen and the app will regularly re-sont the list of bike stations as the device moves and will update the count of available bikes and docks. To save battery, keep auto update off and update sorting by distance on the More Settings screen and update available bikes and docks from the home screen at the push of a button.

**Notes on the Code**

BLUEbikes uses the [General Bikeshare Feed Specification](https://github.com/NABSA/gbfs/blob/master/gbfs.md) to provide [real-time data](https://www.bluebikes.com/system-data). The optional auto-discovery file [gbfs.json](https://gbfs.bluebikes.com/gbfs/gbfs.json) is included in the BlueBike feed and is used to locate all other data files.

When the app is launched the following files are read in order:

File Name | Description
------------ | -------------
system_regions.json | Provides names and ids for each region (city)
station_status.json | Real-time count of bikes and docks available 
station_information.json | Rental station name, location and region id 

The station status file contains a field indicating whether the rental station is currently installed.  Some stations in the system operate on a seasonal basis and will not be available some months.  Stations not installed are not included in the app.

Dart ChangeNotifierProviders are used to store the data model, which consistes of a filtered list of rental stations and current status of each station.  When stations are selected or deselected on the settings screen a list containing ids of selected regions is passed to the model.  Deselectd stations are filtered out of the master list and the main screen is updated.  

The data model also allows sorting of the master list by distance from the device or alphabetic by station name.  The settings screen has a "Sort by distance" switch to toggle how the stations will be sorted and a button to re-sort the list at any time. To keep the list sorted by distance when the device moves Auto Update may be turned on and an update frquency may be set. If this feature is on a timer is used to update the sort.

The count of available bikes and docks may also be updated using a timer using a set frequency. Alternatively, a button at the top of the home screen will retrieve updated availaility on demand. 

![Blue_Bike_Menu](https://user-images.githubusercontent.com/318132/73462708-3ab80200-434a-11ea-89bd-fba4b81015bd.png)
![Blue_Bike_Settings](https://user-images.githubusercontent.com/318132/73462709-3ab80200-434a-11ea-8fe3-5d0e02550849.png)

