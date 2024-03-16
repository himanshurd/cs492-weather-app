import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:cs492_weather_app/models/weather_forecast.dart';
import '../../models/user_location.dart'; 
import '../location/location.dart';

class WeatherScreen extends StatefulWidget {
  final Function getLocation;
  final Function getForecasts;
  final Function getForecastsHourly;
  final Function setLocation;

  const WeatherScreen({
    Key? key,
    required this.getLocation,
    required this.getForecasts,
    required this.getForecastsHourly,
    required this.setLocation,
  }) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 150,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue, Colors.lightBlueAccent],
              ),
            ),
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 10),
                  Text(
                    'My Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Display location information (city, state, ZIP)
                  _buildLocationInfo(),
                  SizedBox(height: 10),
                  Text(
                    DateFormat.yMMMMd().add_jm().format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  widget.getLocation() != null &&
                          widget.getForecasts().isNotEmpty
                      ? ForecastWidget(
                          location: widget.getLocation(),
                          forecasts: widget.getForecastsHourly(),
                        )
                      : LocationWidget(widget: widget),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget to display location information (city, state, ZIP)
  Widget _buildLocationInfo() {
    UserLocation? location = widget.getLocation();
    if (location != null) {
      return Column(
        children: [
          Text(
            location.city,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Text(
            location.state,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Text(
            location.zip,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      );
    } else {
      return Text(
        "Location unavailable",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      );
    }
  }
}

class ForecastWidget extends StatelessWidget {
  final UserLocation location;
  final List<WeatherForecast> forecasts;

  const ForecastWidget({
    Key? key,
    required this.location,
    required this.forecasts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group forecasts by day
    Map<DateTime, List<WeatherForecast>> groupedForecasts = {};
    forecasts.forEach((forecast) {
      DateTime forecastDate = DateTime(forecast.forecastTime.year,
          forecast.forecastTime.month, forecast.forecastTime.day);
      if (!groupedForecasts.containsKey(forecastDate)) {
        groupedForecasts[forecastDate] = [];
      }
      groupedForecasts[forecastDate]!.add(forecast);
    });

    return Column(
      children: groupedForecasts.entries.map((entry) {
        return Column(
          children: [
            SizedBox(height: 20),
            Text(
              DateFormat('EEEE, MMMM d').format(entry.key),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: entry.value.map((forecast) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        _selectWeatherIcon(forecast
                            .shortForecast), // Select weather icon based on forecast description
                        SizedBox(height: 5),
                        Text(
                          DateFormat('h:mm a').format(forecast.forecastTime),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          forecast.shortForecast,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '${forecast.temperature}º',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _selectWeatherIcon(String description) {
    String iconPath = 'assets/sql/thunder.svg';

    print('Description: $description');

    if (description.toLowerCase().contains('sunny')) {
      iconPath = 'assets/sql/day.svg';
    } else if (description.toLowerCase().contains('rain')) {
      iconPath = 'assets/sql/rainy-1.svg';
    } else if (description.toLowerCase().contains('snow')) {
      iconPath = 'assets/sql/snowy-1.svg';
    } else if (description.toLowerCase().contains('mostly clear') ||
        description.toLowerCase().contains('partly cloudy')) {
      iconPath = 'assets/sql/cloudy-day-1.svg';
    } else if (description.toLowerCase().contains('clear')) {
      iconPath = 'assets/sql/day.svg';
    }

    return SvgPicture.asset(
      iconPath,
      width: 50,
      height: 50,
      color: Colors.white,
    );
  }
}

class LocationWidget extends StatelessWidget {
  final WeatherScreen widget;

  const LocationWidget({
    Key? key,
    required this.widget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Requires a location to begin",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Location(
                  setLocation: widget.setLocation,
                  getLocation: widget.getLocation,
                ),
              ),
            );
          },
          child: Text('Set Location'),
        ),
      ],
    );
  }
}
