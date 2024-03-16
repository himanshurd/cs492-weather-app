import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';

const allowedNation = "United States";

class UserLocation {
  double latitude;
  double longitude; 
  String city;
  String state;
  String zip;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.zip,
  });

  @override
  bool operator ==(Object other) =>
      other is UserLocation &&
      city == other.city &&
      state == other.state &&
      zip == other.zip;

  @override
  int get hashCode => Object.hash(city, state, zip);

  String toJsonString() {
    Map<String, dynamic> mappedObject = {
      "latitude": latitude,
      "longitude": longitude,
      "city": city,
      "state": state,
      "zip": zip
    };

    return jsonEncode(mappedObject);
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(), 
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
    );
  }
}

Future<UserLocation?> getLocationFromAddress(
    String city, String state, String zip) async {
  String addressString = "$city $state $zip";

  try {
    List<Location> locations = await locationFromAddress(addressString);
    return getLocationFromCoords(locations[0].latitude, locations[0].longitude);
  } on NoResultFoundException {
    return null;
  }
}

Future<UserLocation> getLocationFromGPS() async {
  Position position = await _determinePosition();
  return getLocationFromCoords(position.latitude, position.longitude);
}

Future<UserLocation> getLocationFromCoords(
    double latitude, double longitude) async {
  String city = "";
  String state = "";
  String zip = "";

  List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);

  for (int i = 0; i < placemarks.length; i++) {
    if (city == "") {
      city = placemarks[i].locality!;
    }
    if (state == "") {
      state = placemarks[i].administrativeArea!;
    }
    if (zip == "") {
      zip = placemarks[i].postalCode!;
    }
  }

  if (city.isEmpty || state.isEmpty || zip.isEmpty) {
    throw FormatException('Failed to load UserLocation.');
  }

  return UserLocation(
    latitude: latitude,
    longitude: longitude,
    city: city,
    state: state,
    zip: zip,
  );
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied.');
  }

  return await Geolocator.getCurrentPosition();
}
