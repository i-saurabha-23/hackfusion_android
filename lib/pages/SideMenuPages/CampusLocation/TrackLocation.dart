import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hackfusion_android/All_Constant.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class TrackPage extends StatefulWidget {
  @override
  _TrackPageState createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  Position? _currentPosition;
  bool _isInsideStore = false;
  String _currentStore = '';
  late StreamSubscription<Position> _positionStream;
  List<Map<String, dynamic>> storeLocations = [];
  DateTime? _lastUpdate;

  late TwilioFlutter twilioFlutter;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _fetchStoreLocations();

    // Initialize TwilioFlutter
    twilioFlutter = TwilioFlutter(
      accountSid: Twilio_accountSid,
      authToken: Twilio_authToken,
      twilioNumber: TwilioNumber,
    );
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    _getCurrentLocation();
    _startLocationTracking();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
      setState(() {
        _currentPosition = position;
        _lastUpdate = DateTime.now();
        _checkIfInsideStore();
      });
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  Future<void> _fetchStoreLocations() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      QuerySnapshot snapshot = await firestore.collection('locations').get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        setState(() {
          storeLocations = [
            {'name': 'A', 'lat': doc['StoreA']['lat'], 'lng': doc['StoreA']['lng']},
            {'name': 'B', 'lat': doc['StoreB']['lat'], 'lng': doc['StoreB']['lng']},
            {'name': 'C', 'lat': doc['StoreC']['lat'], 'lng': doc['StoreC']['lng']},
            {'name': 'D', 'lat': doc['StoreD']['lat'], 'lng': doc['StoreD']['lng']},
          ];
        });
      }
    } catch (e) {
      print("Error fetching store locations: $e");
    }
  }

  void _startLocationTracking() {
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 1), // 1-second interval for updating location
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Location tracking is active",
          notificationTitle: "Location Tracking",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        _currentPosition = position;
        _lastUpdate = DateTime.now();
        _checkIfInsideStore();
      });

      // Check every 2 seconds if the user is still inside the store area
      Future.delayed(const Duration(seconds: 2), () {
        _checkIfInsideStore(); // Recheck location
      });
    });
  }

  void _checkIfInsideStore() {
    if (_currentPosition == null || storeLocations.isEmpty) return;

    double latA = storeLocations[0]['lat'];
    double lngA = storeLocations[0]['lng'];
    double latB = storeLocations[1]['lat'];
    double lngB = storeLocations[1]['lng'];
    double latC = storeLocations[2]['lat'];
    double lngC = storeLocations[2]['lng'];
    double latD = storeLocations[3]['lat'];
    double lngD = storeLocations[3]['lng'];

    double minLat = latA < latB ? latA : latB;
    minLat = minLat < latC ? minLat : latC;
    minLat = minLat < latD ? minLat : latD;

    double maxLat = latA > latB ? latA : latB;
    maxLat = maxLat > latC ? maxLat : latC;
    maxLat = maxLat > latD ? maxLat : latD;

    double minLng = lngA < lngB ? lngA : lngB;
    minLng = minLng < lngC ? minLng : lngC;
    minLng = minLng < lngD ? minLng : lngD;

    double maxLng = lngA > lngB ? lngA : lngB;
    maxLng = maxLng > lngC ? maxLng : lngC;
    maxLng = maxLng > lngD ? maxLng : lngD;

    if (_currentPosition!.latitude >= minLat &&
        _currentPosition!.latitude <= maxLat &&
        _currentPosition!.longitude >= minLng &&
        _currentPosition!.longitude <= maxLng) {
      if (!_isInsideStore) {
        setState(() {
          _isInsideStore = true;
          _currentStore = 'Store Area';
        });
      }
    } else {
      if (_isInsideStore) {
        setState(() {
          _isInsideStore = false;
          _currentStore = '';
        });
        _showLeavingStoreDialog();
      }
    }
  }

  Widget _buildLocationVisualizer() {
    if (storeLocations.isEmpty || _currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      margin: const EdgeInsets.all(16),
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: LocationPainter(
          storeLocations: storeLocations,
          currentPosition: _currentPosition!,
          isInside: _isInsideStore,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (_currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting location...'),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildCoordinateRow(
              icon: Icons.ads_click,
              label: 'Latitude',
              value: _currentPosition!.latitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 8),
            _buildCoordinateRow(
              icon: Icons.add_chart,
              label: 'Longitude',
              value: _currentPosition!.longitude.toStringAsFixed(6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinateRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  void _showLeavingStoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('You Are Leaving'),
          content: const Text('You are leaving the area. Your payment may be deducted. Do you want to continue?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _sendSMS(); // Send SMS when the user confirms
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Method to send SMS using Twilio
  void _sendSMS() async {
    String message = "Respected Parent, your child Piyush left the college at ${DateTime.now()}. Please take care of it. 🚨📱";
    String toNumber = "+917249268699"; // Replace with the recipient's number

    try {
      await twilioFlutter.sendSMS(
        toNumber: toNumber,
        messageBody: message,
      );
      print("SMS sent successfully!");
    } catch (e) {
      print("Failed to send SMS: $e");
    }
  }

  @override
  void dispose() {
    _positionStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isInsideStore ? "Inside $_currentStore" : "Outside Stores"),
        backgroundColor: _isInsideStore ? Colors.green : Colors.red,
      ),
      body: Column(
        children: [
          _buildLocationVisualizer(),
          _buildLocationInfo(),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: storeLocations.length,
              itemBuilder: (context, index) {
                var store = storeLocations[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(store['name'])),
                  title: Text('Point ${store['name']}'),
                  subtitle: Text(
                      'Lat: ${store['lat'].toStringAsFixed(6)}\nLng: ${store['lng'].toStringAsFixed(6)}'
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LocationPainter extends CustomPainter {
  final List<Map<String, dynamic>> storeLocations;
  final Position currentPosition;
  final bool isInside;

  LocationPainter({
    required this.storeLocations,
    required this.currentPosition,
    required this.isInside,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (var location in storeLocations) {
      minLat = min(minLat, location['lat']);
      maxLat = max(maxLat, location['lat']);
      minLng = min(minLng, location['lng']);
      maxLng = max(maxLng, location['lng']);
    }

    List<Offset> points = storeLocations.map((location) {
      double x = (location['lng'] - minLng) / (maxLng - minLng) * size.width;
      double y = (location['lat'] - minLat) / (maxLat - minLat) * size.height;
      return Offset(x, size.height - y);
    }).toList();

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final pointPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, pointPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: storeLocations[i]['name'],
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, points[i].translate(-5, -20));
    }

    double currentX = (currentPosition.longitude - minLng) / (maxLng - minLng) * size.width;
    double currentY = (currentPosition.latitude - minLat) / (maxLat - minLat) * size.height;

    final currentPaint = Paint()
      ..color = isInside ? Colors.green : Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(currentX, size.height - currentY), 8, currentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}