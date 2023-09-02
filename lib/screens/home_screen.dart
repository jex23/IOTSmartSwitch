import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:circular/circular.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:semicircle_indicator/semicircle_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference();

  Map<String, bool> relayValues = {
    'Relay1': false,
    'Relay2': false,
    'Relay3': false,
    'Relay4': false,
    'Relay5': false,
    'Relay6': false,
  };

  double voltageValue = 0.0;
  int voltageValINT = 0;
  double frequencyValue = 0.0;
  double currentValue = 0.0;
  double energyValue = 0.0;
  double pfValue = 0.0;
  double powerValue = 0.0;
  bool radState = false;
  bool isAutoTripOff = false;

  // Declare the SharedPreferences variable
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    for (String relayName in relayValues.keys) {
      _databaseReference
          .child('Relay')
          .child(relayName)
          .onValue
          .listen((event) {
        setState(() {
          relayValues[relayName] = event.snapshot.value as bool? ?? false;
        });
      });
    }
    _initSharedPreferences();
    _databaseReference.child('PZEM').child('voltage').onValue.listen((event) {
      setState(() {
        voltageValue = (event.snapshot.value as double?) ?? 0.0;
        voltageValINT = voltageValue.toInt();
      });
    });

    _databaseReference.child('PZEM').child('frequency').onValue.listen((event) {
      setState(() {
        frequencyValue = (event.snapshot.value as double?) ?? 0.0;
      });
    });
    _databaseReference.child('PZEM').child('current').onValue.listen((event) {
      setState(() {
        currentValue = (event.snapshot.value as double?) ?? 0.0;
      });
    });
    _databaseReference.child('PZEM').child('energy').onValue.listen((event) {
      setState(() {
        energyValue = (event.snapshot.value as double?) ?? 0.0;
      });
    });
    _databaseReference.child('PZEM').child('power').onValue.listen((event) {
      setState(() {
        pfValue = (event.snapshot.value as double?) ?? 0.0;
      });
    });
    _databaseReference.child('PZEM').child('power').onValue.listen((event) {
      setState(() {
        powerValue = (event.snapshot.value as double?) ?? 0.0;
      });
    });

    _databaseReference.child('RadiusState').onValue.listen((event) {
      setState(() {
        radState = (event.snapshot.value as bool?) ?? false;
      });
    });
    if (isAutoTripOff && !radState) {
      _updateRelayValuesInFirebase({
        'Relay1': false,
        'Relay2': false,
        'Relay3': false,
        'Relay4': false,
        'Relay5': false,
        'Relay6': false,
      });
    }
  }

  // Method to initialize SharedPreferences
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    isAutoTripOff = _prefs.getBool('isAutoTripOff') ??
        false; // Initialize isAutoTripOff from shared preferences
    setState(() {});
  }

  // Method to update isAutoTripOff and store it in SharedPreferences
  Future<void> _updateIsAutoTripOff(bool newValue) async {
    // Update the value in SharedPreferences
    await _prefs.setBool('isAutoTripOff', newValue);
    _databaseReference.child('AutoTripBolVal').set(newValue);

    // Update the UI with the new value
    setState(() {
      isAutoTripOff = newValue;
    });
  }

  void _updateRelayValuesInFirebase(Map<String, bool> newRelayValues) {
    newRelayValues.forEach((relayName, newValue) {
      _databaseReference
          .child('Relay')
          .child(relayName)
          .set(newValue)
          .then((_) {
        print('Relay $relayName updated in Firebase');
      }).catchError((error) {
        print('Error updating relay $relayName: $error');
      });
    });
  }

  void updateRelayValue(String relayName, bool newValue) {
    _databaseReference.child('Relay').child(relayName).set(newValue);
  }

  Widget buildCircularIndicator(
      String title, double value, Color color, IconData icon) {
    return CircularPercentIndicator(
      radius: 60.0,
      lineWidth: 10.0,
      animation: true,
      percent: value,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 25,
            color: color,
          ),
          SizedBox(height: 5),
          Text(title),
          SizedBox(height: 5),
          Text(
            title == 'Current' ? '$currentValue A' : '$frequencyValue C',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
        ],
      ),
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: Colors.grey,
      progressColor: color,
    );
  }

  Widget buildEnergyCard(
      double energyValue,
      String unit,
      IconData icon,
      Color iconColor,
      String title,
      double maxEnergyValue,
      Color progressColor) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Text(title, style: TextStyle(fontSize: 15)),
                  Text(' $energyValue $unit',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(icon, color: iconColor),
                ],
              ),
              SizedBox(height: 10),
              LinearPercentIndicator(
                width: 150.0,
                lineHeight: 10.0,
                animation: true,
                percent: energyValue / maxEnergyValue,
                // Calculate the actual percentage
                linearStrokeCap: LinearStrokeCap.roundAll,
                progressColor: progressColor,
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRelayCard(String relayName) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.power, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    relayName,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Status: ${relayValues[relayName]! ? 'On' : 'Off'}',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              CupertinoSwitch(
                value: relayValues[relayName] ?? false,
                onChanged: (newValue) {
                  setState(() {
                    relayValues[relayName] = newValue;
                  });
                  updateRelayValue(relayName, newValue);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Realtime Monitoring',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent),
                )
              ],
            ),
            SizedBox(height: 10),
            SemicircularIndicator(
                radius: 100,
                color: Colors.blueAccent.shade400,
                backgroundColor: Colors.greenAccent.shade700,
                strokeWidth: 13,
                bottomPadding: 0,
                contain: true,
                child: Column(
                  children: [
                    Text(
                      '$voltageValINT V',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent.shade400),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text('Voltage',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black))
                  ],
                )),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: buildCircularIndicator(
                        'Current',
                        currentValue / 350.0,
                        Colors.blueAccent.shade400,
                        Icons.flash_on),
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: buildCircularIndicator(
                        'Temperature',
                        frequencyValue / 350.0,
                        Colors.red,
                        Icons.local_fire_department),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                buildEnergyCard(energyValue, 'kWh', Icons.lightbulb,
                    Colors.purple, 'Energy', 0.001333, Colors.purple),
                buildEnergyCard(frequencyValue.toInt() - 7.6, 'Hz', Icons.signal_cellular_alt,
                    Colors.orange, 'Frequency', 200, Colors.orange),
              ],
            ),
            Row(
              children: [
                buildEnergyCard(
                  pfValue,
                  '',
                  Icons.auto_graph,
                  Colors.amber,
                  'Power Factor',
                  1.10,
                  Colors.amber,
                ),
                buildEnergyCard(powerValue, 'W', Icons.bolt, Colors.red,
                    'Power', 1.0, Colors.red),
              ],
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic Trip Off Switch',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Column(
                      children: [
                        CupertinoSwitch(
                          value: isAutoTripOff,
                          onChanged: (value) {
                            _updateIsAutoTripOff(value);

                            // End line of CupertinoSwitch onChanged callback
                            // });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Status:',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              isAutoTripOff ? 'On' : 'Off',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildRelayCard('Relay1'),
                    buildRelayCard('Relay2'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildRelayCard('Relay3'),
                    buildRelayCard('Relay4'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildRelayCard('Relay5'),
                    buildRelayCard('Relay6'),
                    // Add more relay cards here if needed
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              children: [
                Text(
                  'Voltage: $voltageValue V',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700),
                ),
                Text(
                  'Frequency: $currentValue V',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Is Radius $radState')
          ],
        ),
      )),
    );
  }
}
