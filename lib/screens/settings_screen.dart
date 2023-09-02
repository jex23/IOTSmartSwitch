import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared preferences
import 'package:geocoding/geocoding.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String staticLocation = '';
  String _liveLocationCoordinates = '';
  String _errorMesage = '';
  StreamSubscription<Position>? _positionStream;
  Position? _currentLocation;
  double _distanceBetweenLocations = 0.0;
  String _distanceMessage = '';
  String _Address = '';
  bool radiusState = false;


  void _updateRadiusState(bool newState) async {
    DatabaseReference databaseRef = FirebaseDatabase.instance.reference();
    await databaseRef.child('RadiusState').set(newState);
  }
  void _sendDistanceToFirebase(double distance) async {
    DatabaseReference databaseRef = FirebaseDatabase.instance.reference();
    await databaseRef.child('DevDistance').set(distance);
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        staticLocation =
            'Latitude: ${position.latitude}\nLongitude: ${position.longitude}';
        _currentLocation = position;
      });

      // Store latitude and longitude in shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setDouble('latitude', position.latitude);
      prefs.setDouble('longitude', position.longitude);

      // Get address using reverse geocoding
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          _Address =
              '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
        });
      }
    } catch (e) {
      print('having an error $e');
    }
  }

  void _gettingLiveLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMesage = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMesage = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMesage =
            'Location permissions are permanently denied, we cannot request permissions.';
      });
      return;
    }

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) async {
        if (position != null) {
          setState(() {
            _liveLocationCoordinates =
                '${position.latitude.toString()}, ${position.longitude.toString()}';
          });
          SharedPreferences prefs = await SharedPreferences.getInstance();
          double? storedLatitude = prefs.getDouble('latitude');
          double? storedLongitude = prefs.getDouble('longitude');
          if (storedLatitude != null && storedLongitude != null) {
            _distanceBetweenLocations = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              storedLatitude,
              storedLongitude,

            );
            if (_distanceBetweenLocations <= 10.0) {
              print(_distanceBetweenLocations);
              _distanceMessage = 'you are inside 10 meter radius';
              radiusState = true;
            } else {
              _distanceMessage = 'you are outside 10 meter radius';
              radiusState = false;
              print(_distanceBetweenLocations);
            }
            _updateRadiusState(radiusState); // Update radiusState in Firebase
            // Send the distance to Firebase
            _sendDistanceToFirebase(_distanceBetweenLocations);
          }
        }
      },
    );
  }

  void _getStoredLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? storedLatitude = prefs.getDouble('latitude');
    double? storedLongitude = prefs.getDouble('longitude');

    if (storedLatitude != null && storedLongitude != null) {
      setState(() {
        staticLocation =
            'Latitude: $storedLatitude\nLongitude: $storedLongitude';
      });

      // Get address using reverse geocoding
      List<Placemark> placemarks =
          await placemarkFromCoordinates(storedLatitude, storedLongitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          _Address =
              '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
        });
      }
    } else {
      setState(() {
        staticLocation = 'No stored location found';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _gettingLiveLocation();
    _getStoredLocation();

    // Call this function to load stored location
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.location_pin,
                size: 100,
                color: Colors.deepOrange,
              ),
              Text(
                'Live location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                  'Distance to Live Location: ${_distanceBetweenLocations.toStringAsFixed(2)} meters'),
              SizedBox(
                height: 20,
              ),
              Text(_distanceMessage),
              SizedBox(
                height: 20,
              ),
              Text(_liveLocationCoordinates),
              SizedBox(
                height: 20,
              ),
              Text(_errorMesage),
              SizedBox(
                height: 20,
              ),
              Text(
                'Device location $radiusState',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),

              ),
              SizedBox(
                height: 20,
              ),
              Text(staticLocation),
              SizedBox(
                height: 10,
              ),
              Text(_Address),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                  onPressed: _getCurrentLocation,
                  child: Text('Get Device Position')),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
