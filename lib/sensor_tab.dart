import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'ros_manager.dart';

class SensorTab extends StatefulWidget {
  final RosManager rosManager;

  const SensorTab({super.key, required this.rosManager});

  @override
  State<SensorTab> createState() => _SensorTabState();
}

class _SensorTabState extends State<SensorTab> {
  bool _accelPublishing = false;
  bool _gyroPublishing = false;
  bool _magPublishing = false;
  bool _gpsPublishing = false;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<Position>? _gpsSub;

  void _toggleAccelerometer() {
    if (_accelPublishing) {
      _accelSub?.cancel();
      _accelSub = null;
      setState(() => _accelPublishing = false);
    } else {
      setState(() => _accelPublishing = true);
      _accelSub = accelerometerEvents.listen((event) {
        widget.rosManager.publishVector3Stamped(
          '/Phone2Act/accelerometer',
          {
            "header": {"stamp": {"sec": 0, "nanosec": 0}, "frame_id": "imu"},
            "vector": {"x": event.x, "y": event.y, "z": event.z},
          },
        );
      });
    }
  }

  void _toggleGyroscope() {
    if (_gyroPublishing) {
      _gyroSub?.cancel();
      _gyroSub = null;
      setState(() => _gyroPublishing = false);
    } else {
      setState(() => _gyroPublishing = true);
      _gyroSub = gyroscopeEvents.listen((event) {
        widget.rosManager.publishVector3Stamped(
          '/Phone2Act/gyroscope',
          {
            "header": {"stamp": {"sec": 0, "nanosec": 0}, "frame_id": "imu"},
            "vector": {"x": event.x, "y": event.y, "z": event.z},
          },
        );
      });
    }
  }

  void _toggleMagnetometer() {
    if (_magPublishing) {
      _magSub?.cancel();
      _magSub = null;
      setState(() => _magPublishing = false);
    } else {
      setState(() => _magPublishing = true);
      _magSub = magnetometerEvents.listen((event) {
        widget.rosManager.publishVector3Stamped(
          '/Phone2Act/magnetometer',
          {
            "header": {"stamp": {"sec": 0, "nanosec": 0}, "frame_id": "imu"},
            "vector": {"x": event.x, "y": event.y, "z": event.z},
          },
        );
      });
    }
  }

  void _toggleGPS() async {
    if (_gpsPublishing) {
      _gpsSub?.cancel();
      _gpsSub = null;
      setState(() => _gpsPublishing = false);
      return;
    }

    setState(() => _gpsPublishing = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _gpsPublishing = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _gpsPublishing = false);
        return;
      }
    }

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      widget.rosManager.publishNavSatFix(
        '/Phone2Act/gps',
        {
          "header": {"stamp": {"sec": 0, "nanosec": 0}, "frame_id": "gps"},
          "status": {"status": 0, "service": 1},
          "latitude": position.latitude,
          "longitude": position.longitude,
          "altitude": position.altitude,
          "position_covariance": List.filled(9, 0.0),
          "position_covariance_type": 0,
        },
      );
    });
  }

  void _stopAll() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _gpsSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _magSub = null;
    _gpsSub = null;

    // FIX: Only call setState if the widget is still in the tree
    if (mounted) {
      setState(() {
        _accelPublishing = false;
        _gyroPublishing = false;
        _magPublishing = false;
        _gpsPublishing = false;
      });
    }
  }

  Widget _sensorBox(String name, Color color, bool isPublishing, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isPublishing ? color.withOpacity(0.7) : color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            isPublishing ? '$name\n(Publishing)' : name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _sensorBox('Accelerometer', Colors.blue, _accelPublishing, _toggleAccelerometer),
        _sensorBox('Gyroscope', Colors.red, _gyroPublishing, _toggleGyroscope),
        _sensorBox('Magnetometer', Colors.green, _magPublishing, _toggleMagnetometer),
        _sensorBox('GPS', Colors.orange, _gpsPublishing, _toggleGPS),
      ],
    );
  }
}
