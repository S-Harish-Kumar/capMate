import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart'; // Syncfusion package for better gauges

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  double temperature = 0.0;
  double humidity = 0.0;
  double eegValue = 0.0;
  String stressStatus = 'Normal';
  bool alertShown = false; // Track whether the alert has been shown
  DateTime? alertShownTime; // Time when the alert was shown

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _database.child('sensorData').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          temperature = _getValue(data['temperature']);
          humidity = _getValue(data['humidity']);
          eegValue = _getValue(data['eegValue']);
          stressStatus = data['stressStatus'] ?? 'Normal';

          // Check if stress is detected and if the alert should be shown
          if (stressStatus == 'Stress Detected' && !alertShown) {
            _showMeditationAlert(); // Show alert immediately when stress is detected
          }
        });
      } else {
        print("No data found");
      }
    });
  }

  double _getValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0.0; // Return a default value if the data is null or not a number
  }

  void _showMeditationAlert() {
    int meditationTime = 5; // default meditation time in minutes
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Stress Detected!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You have detected stress.'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Meditation Time:'),
                  DropdownButton<int>(
                    value: meditationTime,
                    items: [1, 2, 3, 4, 5, 10, 15, 20]
                        .map((int value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value minutes'),
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          meditationTime = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Set the alert shown flag and time
                setState(() {
                  alertShown = true;
                  alertShownTime = DateTime.now();
                });
                Navigator.of(context).pop(); // Close the alert
                Navigator.pushReplacement( // Replace current page with TimerPage
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimerPage(minutes: meditationTime),
                  ),
                );

                // Reset the alertShown flag after the meditation time
                Future.delayed(Duration(minutes: meditationTime), () {
                  setState(() {
                    alertShown = false; // Allow alerts again
                  });
                });
              },
              child: Text('Meditate for $meditationTime minutes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildTemperatureHumidityGauges(),
            SizedBox(height: 20),
            _buildEEGGauge(),
            SizedBox(height: 20),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                'Sensor Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
            ),
            ListTile(
              title: Text('Temperature Data'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Add your navigation or action here
              },
            ),
            ListTile(
              title: Text('EEG Data'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Add your navigation or action here
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureHumidityGauges() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Temperature & Humidity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _buildGauge(temperature, 'Temperature', Colors.orange),
              ),
              Flexible(
                child: _buildGauge(humidity, 'Humidity', Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEEGGauge() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'EEG Data',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 10),
          _buildGauge(eegValue, 'EEG', Colors.pink),
          SizedBox(height: 10),
          Text(
            'Stress Status: $stressStatus',
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(double value, String label, Color color) {
    return SizedBox(
      height: 200,
      width: 200,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 100,
            showLabels: false,
            showTicks: false,
            axisLineStyle: AxisLineStyle(
              thickness: 20,
              color: color.withOpacity(0.2),
            ),
            pointers: <GaugePointer>[
              RangePointer(
                value: value,
                width: 20,
                color: color,
                cornerStyle: CornerStyle.bothCurve,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${value.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      label,
                      style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                    ),
                  ],
                ),
                positionFactor: 0.1,
                angle: 90,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimerPage extends StatelessWidget {
  final int minutes;

  TimerPage({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meditation Timer'),
      ),
      body: Center(
        child: TimerWidget(minutes: minutes),
      ),
    );
  }
}

class TimerWidget extends StatefulWidget {
  final int minutes;

  TimerWidget({required this.minutes});

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int remainingSeconds;
  late String timerDisplay;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.minutes * 60; // Convert minutes to seconds
    timerDisplay = _formatDuration(Duration(seconds: remainingSeconds));
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
          timerDisplay = _formatDuration(Duration(seconds: remainingSeconds));
        });
        _startTimer(); // Restart the timer
      } else {
        _showMeditationCompleteDialog();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitsHours = twoDigits(duration.inHours);
    String twoDigitsMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitsSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigitsHours}:${twoDigitsMinutes}:${twoDigitsSeconds}';
  }

  void _showMeditationCompleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Meditation Complete!'),
          content: Text('You have completed your meditation session.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the dashboard
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Meditation Timer',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Text(
          timerDisplay,
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
