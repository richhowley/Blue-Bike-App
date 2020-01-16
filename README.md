# Blue Bikes

A Flutter application that provides information on the Boston bike sharing system Bluebikes.

**Using the App**

BlueBikes uses the [General Bikeshare Feed Specification](https://github.com/NABSA/gbfs/blob/master/gbfs.md) to provide [real-time data](https://www.bluebikes.com/system-data).  

The app lists all bicycle stations in the system along with the number of bikes availabe for rent and the number of docks accepting bicycle returns.  When the app is launched it presents a list of all rental stations in alphabetical order.  The BlueBike system operates in five cities:  Brookline, Cambridge, Somerville, Boston and Everett. Each entry on the list is color-coded by city.

A settings screen allows filtering the list of rental stations by city.  If the location service is enabled, an option to sort by distance from the device, instead of alphanumerically, is offered.  The sort is not updataed as the device is moved but can be manullay updated using the Refresh button on the settings menu.

There is a button on the main screen to update the count of bikes and docks available at each station.

<details>
<summary>Notes on the Code</summary>

The optional auto-discovery file [gbfs.json](https://gbfs.bluebikes.com/gbfs/gbfs.json) is included in the BlueBike feed and is used to locate all other data files.

When the app is launched the following files are read in order:

File Name | Description
------------ | -------------
system_regions.json | Provides names and ids for each region (city)
station_status.json | Real-time count of bikes and docks available 
station_information.json | Rental station name, location and region id 

The station status file contains a field indicating whether the rental station is currently installed.  Some stations in the system operate on a seasonal basis and will not be available some months.  Stations not installed are not included in the app.

A Flutter ChangeNotifierProvider is used to store the data model, which consistes of a filtered list of rental stations and current status of each station.  When stations are selected or deselected on the settings screen a list containing ids of selected regions is passed to the model.  Deselectd stations are filtered out of the master list and the main screen is updated.  

The data model also allows sorting of the master list by distance from the device or alphabetic by station name.  The settings screen has a "Sort by distance" switch to toggle how the stations will be sorted.  Since bicycle renters will probably not need contious resorting due to change of location, a Refresh button calls the sort method of the model on demand.  A modal appears over the settings screen when waiting for the device location.

The count of bikes and docks available may be updated via a button on the main screen.  When the button is pressed the station status data is read and passed to the data model, which causes an update to the interface.

</details>
