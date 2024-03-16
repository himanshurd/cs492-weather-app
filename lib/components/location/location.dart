import 'package:flutter/material.dart';
import '../../models/user_location.dart';
import '../../models/location_database.dart';

class Location extends StatefulWidget {
  // The setter and getter for the active location
  final Function setLocation;
  final Function getLocation;
  final Function? closeEndDrawer;

  const Location(
      {super.key,
      required this.setLocation,
      required this.getLocation,
      this.closeEndDrawer});

  @override
  State<Location> createState() => _LocationState();
}

class _LocationState extends State<Location> {
  // Edit mode allows user to delete stored locations
  bool _editMode = false;

  LocationDatabase? _db;

  final List<UserLocation> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  void _loadDatabase() async {
    LocationDatabase db = await LocationDatabase.open();
    List<UserLocation> locations = await db.getLocations();

    setState(() {
      _db = db;
      _setLocationsFromDatabase(locations);
    });
  }

  void _setLocationsFromDatabase(List<UserLocation> locations) async {
    _locations.addAll(locations);
  }

  void _insertLocationIntoDatabase(UserLocation location) async {
    if (_db != null) {
      _db?.insertLocation(location);
    }
  }

  void _deleteLocationFromDatabase(UserLocation location) async {
    if (_db != null) {
      _db?.deleteLocation(location);
    }
  }

  // When the edit button is pressed, the editMode flips to its opposite
  // true -> false
  // false -> true
  void toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
    });
  }

  // Controller that handle the text boxes
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipController = TextEditingController();

  // When an item from the list is tapped, set the current location to whichever one was tapped
  void tapList(index) {
    widget.closeEndDrawer!();
    widget.setLocation(_locations.elementAt(index));
  }

  // There are two ways to add the location
  // First, if the user enters text into the text boxes, geocoding will attempt to find it.
  void addLocationButtonPressed() async {
    UserLocation? location = await getLocationFromAddress(
        cityController.text, stateController.text, zipController.text);
    if (location != null) {
      updateLocation(location);
    }
  }

  // Second, if the user taps the "Add GPS Location" button, the location is found via geolocation
  void addLocationGPSButtonPressed() async {
    UserLocation location = await getLocationFromGPS();
    updateLocation(location);
  }

  // Update location sets the current location to the passed location
  // Additionally, it adds the location only if the location isn't already in the list
  void updateLocation(UserLocation location) {
    widget.setLocation(location);
    setState(() {
      if (!_locations.contains(location)) {
        _locations.add(location);
        _insertLocationIntoDatabase(location);
      }
    });
  }

  // Delete location removes the location from the list by index
  void deleteLocation(index) {
    setState(() {
      _deleteLocationFromDatabase(_locations.elementAt(index));
      _locations.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _locations.isNotEmpty ? savedListColumn() : userInput();
  }

  Column savedListColumn() {
    return Column(
      children: [
        SizedBox(height: 160, child: userInput()),
        savedLocation(),
        SizedBox(height: 150, child: locationsListWidget()),
      ],
    );
  }

  Row savedLocation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Saved Locations:"),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: toggleEditMode,
          color: const Color.fromRGBO(18, 98, 227, 1.0),
        )
      ],
    );
  }

  ListView locationsListWidget() => ListView.builder(
      itemCount: _locations.length,
      itemBuilder: (context, index) => ListTile(
          title: SizedBox(height: 25, child: listItemText(index)),
          onTap: () {
            tapList(index);
          }));

  Row listItemText(int index) => Row(
        children: [
          SizedBox(
            width: 200,
            child: FittedBox(
              child: Text(
                  "${_locations.elementAt(index).city}, ${_locations.elementAt(index).state}, ${_locations.elementAt(index).zip}"),
            ),
          ),
          (_editMode)
              ? IconButton(
                  onPressed: () {
                    deleteLocation(index);
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Color.fromRGBO(227, 18, 67, 1.0),
                  ))
              : const SizedBox()
        ],
      );

  Column userInput() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: addLocationGPSButtonPressed,
          child: const SizedBox(
            width: 140,
            child: Row(
              children: [
                Text('Add GPS Location'),
                Icon(Icons.location_on_outlined),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocationText(
                labelText: "City", width: 80.0, controller: cityController),
            LocationText(
                labelText: "State", width: 60.0, controller: stateController),
            LocationText(
                labelText: "Zip", width: 70.0, controller: zipController)
          ],
        ),
        ElevatedButton(
          onPressed: addLocationButtonPressed,
          child: const Text('Add Manual Location'),
        ),
      ],
    );
  }
}

class LocationText extends StatefulWidget {
  const LocationText(
      {super.key,
      required this.labelText,
      required this.width,
      required this.controller});

  final String labelText;
  final double width;
  final TextEditingController controller;

  @override
  State<LocationText> createState() => _LocationTextState();
}

class _LocationTextState extends State<LocationText> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        width: widget.width,
        child: TextField(
            controller: widget.controller,
            style: const TextStyle(fontSize: 15.0, height: 1.0),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: widget.labelText,
            )),
      ),
    );
  }
}
