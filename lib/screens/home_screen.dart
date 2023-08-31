import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:circular/circular.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:semicircle_indicator/semicircle_indicator.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.reference();

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

  @override
  void initState() {
    super.initState();
    for (String relayName in relayValues.keys) {
      _databaseReference.child('Relay').child(relayName).onValue.listen((event) {
        setState(() {
          relayValues[relayName] = event.snapshot.value as bool? ?? false;
        });
      });
    }

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
  }

  void updateRelayValue(String relayName, bool newValue) {
    _databaseReference.child('Relay').child(relayName).set(newValue);
  }

  Widget buildCircularIndicator(String title, double value, Color color, IconData icon) {
    return CircularPercentIndicator(
      radius: 60.0,
      lineWidth: 10.0,
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
  Widget buildEnergyCard(double energyValue, String unit, IconData icon, Color iconColor , String title, double maxEnergyValue, Color progressColor ) {
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
                  SizedBox(width: 10,),
                  Text(title, style: TextStyle(fontSize: 15)),
                  Text(' $energyValue $unit', style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(icon, color: iconColor),
                ],
              ),
              SizedBox(height: 10),
              LinearPercentIndicator(
                width: 150.0,
                lineHeight: 10.0,
                percent: energyValue / maxEnergyValue, // Calculate the actual percentage
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
              SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 10,),
                  Text('Realtime Monitoring',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent),)
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
                    SizedBox(height: 5,),
                    Text('Voltage',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black))
                  ],
                )
              ),
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
                      child: buildCircularIndicator('Current', currentValue / 350.0, Colors.blueAccent.shade400, Icons.flash_on),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: buildCircularIndicator('Temperature', frequencyValue / 350.0, Colors.red, Icons.local_fire_department),
                    ),
                  ),
                ],
              ),
              Row(children: [

                buildEnergyCard(energyValue, 'kWh', Icons.lightbulb, Colors.blue ,'Energy', 100, Colors.blue),
                buildEnergyCard(frequencyValue, 'Hz', Icons.signal_cellular_alt, Colors.orange ,'Frequency', 200,Colors.orange ),
              ],),
              Row(children: [

                buildEnergyCard(pfValue, '', Icons.auto_graph, Colors.amber, 'Power Factor', 100,Colors.amber,),
                buildEnergyCard(powerValue, 'W', Icons.bolt,Colors.red, 'Power', 200,Colors.red),
              ],),

              SizedBox(height: 20),
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
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Frequency: $currentValue V',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        )
      ),
    );
  }
}
