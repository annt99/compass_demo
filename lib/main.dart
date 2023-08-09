import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _angle = 0.0;
  String _formattedAngle = 'East 0°';
  String angle = 'East 0°';
  Position? _currentPosition;
  String city = 'Unknown';
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (isLocationServiceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentPosition = position;
        });
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks[0];
          setState(() {
            city = placemark.locality ?? 'Unknown';
          });
        }
      }
    }
  }

  String _getFormattedAngle(double angle) {
    int degrees = (angle * 180 / pi).round();
    String direction = formatCompassDirection(degrees % 360);
    int formattedDegrees = degrees % 360; // Convert to 0-359 range
    return '$direction $formattedDegrees°';
  }

  String formatCompassDirection(int degrees) {
    if ((degrees >= 0 && degrees < 22.5) || degrees >= 337.5) {
      return 'North'; // North
    } else if (degrees >= 22.5 && degrees < 67.5) {
      return 'Northeast'; // Northeast
    } else if (degrees >= 67.5 && degrees < 112.5) {
      return 'East'; // East
    } else if (degrees >= 112.5 && degrees < 157.5) {
      return 'Southeast'; // Southeast
    } else if (degrees >= 157.5 && degrees < 202.5) {
      return 'South'; // South
    } else if (degrees >= 202.5 && degrees < 247.5) {
      return 'Southwest'; // Southwest
    } else if (degrees >= 247.5 && degrees < 292.5) {
      return 'West'; // West
    } else if (degrees >= 292.5 && degrees < 337.5) {
      return 'Northwest'; // Northwest
    } else {
      return 'L'; // Invalid or unspecified
    }
  }

  String formatCoordinates(double coordinate, String direction) {
    int degrees = coordinate.floor();
    double minutesDouble = (coordinate - degrees) * 60;
    int minutes = minutesDouble.floor();
    double secondsDouble = (minutesDouble - minutes) * 60;
    int seconds = secondsDouble.floor();

    return "$direction$degrees°${minutes.toString().padLeft(2, '0')}'${seconds.toString().padLeft(2, '0')}\"";
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        double? direction = snapshot.data!.heading;
        angle = '${snapshot.data!.accuracy}';

        if (direction == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Image.asset(
              'assets/images/img_compass2.png',
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Transform.rotate(
                angle: (direction * (math.pi / 180)) * -1,
                child: Image.asset(
                  'assets/images/img_compass2.png',
                ),
              ),
            ),
            const SizedBox(height: 50),
            Text(
              _getFormattedAngle((direction * (math.pi / 180))),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            'Compass',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          automaticallyImplyLeading: true,
          elevation: 0,
          backgroundColor: Colors.black,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              alignment: Alignment.center,
              child: Stack(
                children: [
                  _buildCompass(),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RotatedBox(
                          quarterTurns: 2,
                          child: Icon(
                            Icons.eject,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                        Text(
                          '|',
                          style:
                              TextStyle(color: Color(0xffF60000), fontSize: 40),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.place, color: Color(0xffF60000)),
                    const SizedBox(width: 13),
                    Text(
                      city,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (_currentPosition != null)
                  Text(
                    '${formatCoordinates(_currentPosition!.latitude, _currentPosition!.latitude >= 0 ? 'N' : 'S')}    ${formatCoordinates(_currentPosition!.longitude, _currentPosition!.longitude >= 0 ? 'E' : 'W')}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
