import 'dart:convert';

import './user_location.dart';
import 'package:http/http.dart' as http;

class WeatherForecast {
  final String name;
  final bool isDaytime;
  final int temperature;
  final String windSpeed;
  final String windDirection;
  final String shortForecast;
  final String detailedForecast;
  final DateTime forecastTime; 

  const WeatherForecast({
    required this.name,
    required this.isDaytime,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.shortForecast,
    required this.detailedForecast,
    required this.forecastTime, 
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      name: json['name'],
      isDaytime: json['isDaytime'],
      temperature: json['temperature'],
      windSpeed: json['windSpeed'],
      windDirection: json['windDirection'],
      shortForecast: json['shortForecast'],
      detailedForecast: json['detailedForecast'],
      forecastTime: DateTime.parse(json['startTime']),
    );
  }
}

Future<List<WeatherForecast>> getHourlyForecasts(UserLocation location) async {
  return getWeatherForecasts(location, true);
}

Future<List<WeatherForecast>> getTwiceDailyForecasts(
    UserLocation location) async {
  return getWeatherForecasts(location, false);
}

Future<List<WeatherForecast>> getWeatherForecasts(
    UserLocation location, bool hourly) async {
  // Casts latitude and longitude to strings with 2 fixed digits
  String lat = location.latitude.toStringAsFixed(2);
  String long = location.longitude.toStringAsFixed(2);

  // Send a request to the weather API to get forecast details
  String forecastUrl = "https://api.weather.gov/points/$lat,$long";
  http.Response forecastResponse = await http.get(Uri.parse(forecastUrl));
  final Map<String, dynamic> forecastJson = jsonDecode(forecastResponse.body);

  // Grabs the forecasts URL from the JSON response
  final String currentForecastsUrl = hourly
      ? forecastJson["properties"]["forecastHourly"]
      : forecastJson["properties"]["forecast"];

  // Send another request to the API which will return the specifics of the forecasts
  http.Response currentForecastsResponse =
      await http.get(Uri.parse(currentForecastsUrl));
  final Map<String, dynamic> currentForecastsJson =
      jsonDecode(currentForecastsResponse.body);

  // Gets the list of forecasts from the forecast request
  List<dynamic> forecastJsons = currentForecastsJson["properties"]["periods"];

  // Use JSON data to create list of WeatherForecast objects
  List<WeatherForecast> forecasts = [];
  for (final forecastJson in forecastJsons) {
    forecasts.add(WeatherForecast.fromJson(forecastJson));
  }

  return forecasts;
}

Future<List<WeatherForecast>> getWeeklyForecasts(UserLocation location) async {
  // Casts latitude and longitude to strings with 2 fixed digits
  String lat = location.latitude.toStringAsFixed(2);
  String long = location.longitude.toStringAsFixed(2);

  // Send a request to the weather API to get weekly forecast details
  String weeklyForecastUrl = "https://api.weather.gov/gridpoints/PDT/$lat,$long/forecast";
  http.Response weeklyForecastResponse = await http.get(Uri.parse(weeklyForecastUrl));
  final Map<String, dynamic> weeklyForecastJson = jsonDecode(weeklyForecastResponse.body);

  // Gets the list of forecast periods from the weekly forecast JSON response
  List<dynamic> forecastPeriods = weeklyForecastJson["properties"]["periods"];

  // Use JSON data to create list of WeatherForecast objects for weekly forecast
  List<WeatherForecast> weeklyForecasts = [];
  for (final forecastPeriod in forecastPeriods) {
    weeklyForecasts.add(WeatherForecast.fromJson(forecastPeriod));
  }

  return weeklyForecasts;
}
