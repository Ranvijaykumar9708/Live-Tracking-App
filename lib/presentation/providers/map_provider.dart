import 'dart:async';

import 'dart:math' show cos, sin, atan2, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';
import '../../core/constants/map_style.dart';
import '../../core/utils/marker_generator.dart';
import '../../domain/repositories/map_repository.dart';
import '../../data/repositories/map_repository_impl.dart';

enum VehicleType { bike, auto, sedan, suv }

class MapProvider extends ChangeNotifier {
  final MapRepository _repository = MapRepositoryImpl('AIzaSyBcVNOX83jHMMtpeH5Dk9rfUT6d6vGvVM0');
  
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  final List<LatLng> _polylineCoordinates = [];
  int _currentCoordinateIndex = 0;
  Timer? _movementTimer;
  
  // Marker data
  LatLng? _carLocation;
  double _carBearing = 0.0;

  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  LatLng? get carLocation => _carLocation;

  // Map Features
  MapType mapType = MapType.normal;
  bool isTrafficEnabled = false;

  // Dynamic locations
  LatLng? sourceLocation;
  LatLng? destinationLocation;

  // Distance and Duration
  String? distanceText;
  String? durationText;

  // To store numeric values for live countdown
  int _totalDistanceMeters = 0;
  int _totalDurationSeconds = 0;

  bool _isRideStarted = false;
  bool get isRideStarted => _isRideStarted;

  bool _isFindingDriver = false;
  bool get isFindingDriver => _isFindingDriver;

  Map<String, String>? driverDetails;
  int? estimatedFare;

  VehicleType selectedVehicle = VehicleType.sedan;
  BitmapDescriptor? _customCarIcon;

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Standard light map style
    centerOnUser(); // Automatically center on user when map is ready
  }

  void toggleMapType() {
    mapType = mapType == MapType.normal ? MapType.satellite : MapType.normal;
    notifyListeners();
  }

  String? get currentMapStyle {
    return mapType == MapType.satellite ? null : MapStyle.darkTheme;
  }

  void toggleTraffic() {
    isTrafficEnabled = !isTrafficEnabled;
    notifyListeners();
  }

  void selectVehicle(VehicleType type) {
    selectedVehicle = type;
    notifyListeners();
  }

  void centerOnUser() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    LatLng target = LatLng(position.latitude, position.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
  }

  Future<void> updateLocations(LatLng source, LatLng destination) async {
    sourceLocation = source;
    destinationLocation = destination;
    distanceText = null;
    durationText = null;
    
    _markers.clear();
    _polylines.clear();
    _polylineCoordinates.clear();
    _movementTimer?.cancel();
    
    _markers.add(
      Marker(
        markerId: const MarkerId('source'),
        position: sourceLocation!,
        infoWindow: const InfoWindow(title: 'Start'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationLocation!,
        infoWindow: const InfoWindow(title: 'End'),
      ),
    );
    
    _carLocation = sourceLocation;
    _updateCarMarker();
    
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(sourceLocation!, 14));
    
    await _getPolyline();
  }

  Future<void> _getPolyline() async {
    if (sourceLocation == null || destinationLocation == null) return;
    
    try {
      final distDurData = await _repository.getDistanceAndDuration(sourceLocation!, destinationLocation!);
      distanceText = distDurData['distance'] as String?;
      durationText = distDurData['duration'] as String?;
      _totalDistanceMeters = (distDurData['distanceValue'] as num?)?.toInt() ?? 0;
      _totalDurationSeconds = (distDurData['durationValue'] as num?)?.toInt() ?? 0;
      
      _calculateFare();
      
      final points = await _repository.getRoutePolylines(sourceLocation!, destinationLocation!);
      if (points.isNotEmpty) {
        _polylineCoordinates.addAll(points);
        
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.black, // Uber-style pure black polyline
            points: _polylineCoordinates,
            width: 4,
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Route Fetch Error: $e");
    }
  }

  void _calculateFare() {
    // Basic calculation: Base fare + (₹15/km) + (₹2/min)
    int baseFare;
    switch (selectedVehicle) {
      case VehicleType.bike: baseFare = 20; break;
      case VehicleType.auto: baseFare = 40; break;
      case VehicleType.sedan: baseFare = 60; break;
      case VehicleType.suv: baseFare = 100; break;
    }
    double km = _totalDistanceMeters / 1000;
    double mins = _totalDurationSeconds / 60;
    
    estimatedFare = (baseFare + (km * 15) + (mins * 2)).round();
  }

  void setSelectedVehicle(VehicleType type) {
    selectedVehicle = type;
    if (_totalDistanceMeters > 0) {
      _calculateFare();
    }
    notifyListeners();
  }

  void _startMovingCar() {
    _currentCoordinateIndex = 0;
    _movementTimer?.cancel();
    
    // Move marker every 500ms
    _movementTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_currentCoordinateIndex < _polylineCoordinates.length - 1) {
        _carLocation = LatLng(
          _polylineCoordinates[_currentCoordinateIndex].latitude,
          _polylineCoordinates[_currentCoordinateIndex].longitude,
        );

        // --- Live Distance/Duration Updates ---
        if (_polylineCoordinates.isNotEmpty) {
          double fractionRemaining = (_polylineCoordinates.length - _currentCoordinateIndex) / _polylineCoordinates.length;
          
          int currentDistMeters = (_totalDistanceMeters * fractionRemaining).round();
          int currentDurSeconds = (_totalDurationSeconds * fractionRemaining).round();

          // Format Distance
          if (currentDistMeters > 1000) {
            distanceText = "${(currentDistMeters / 1000).toStringAsFixed(1)} km";
          } else {
            distanceText = "$currentDistMeters m";
          }

          // Format Duration
          int mins = (currentDurSeconds / 60).round();
          if (mins == 0) mins = 1; // Show at least 1 min
          durationText = "$mins mins";
        }

        final startCoord = _polylineCoordinates[_currentCoordinateIndex];
        final endCoord = _polylineCoordinates[_currentCoordinateIndex + 1];

        // Calculate bearing
        _carBearing = _calculateBearing(startCoord, endCoord);
        _carLocation = endCoord;

        _updateCarMarker();
        _animateCameraToCar();
        
        _currentCoordinateIndex++;
        notifyListeners();
      } else {
        timer.cancel(); // Reached destination
      }
    });
  }

  Future<void> _generateCarIcon() async {
    IconData iconData;
    Color color;
    switch (selectedVehicle) {
      case VehicleType.bike:
        iconData = Icons.two_wheeler;
        break;
      case VehicleType.auto:
        iconData = Icons.electric_rickshaw;
        break;
      case VehicleType.sedan:
        iconData = Icons.directions_car;
        break;
      case VehicleType.suv:
        iconData = Icons.airport_shuttle;
        break;
    }
    color = Colors.black; // Uber-style black vehicles
    _customCarIcon = await MarkerGenerator.createCustomMarker(iconData, color);
  }

  void startRide() async {
    _isFindingDriver = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3)); // Simulate network search
    
    _isFindingDriver = false;
    driverDetails = {
      'name': 'Ramesh Kumar',
      'rating': '4.8',
      'carNumber': 'UP14 CD 1234',
    };

    await _generateCarIcon();
    _isRideStarted = true;
    _startMovingCar();
    notifyListeners();
  }

  void endRide() {
    _isRideStarted = false;
    _isFindingDriver = false;
    driverDetails = null;
    estimatedFare = null;
    _movementTimer?.cancel();
    distanceText = null;
    durationText = null;
    _polylines.clear();
    _markers.removeWhere((m) => m.markerId == const MarkerId('car'));
    _markers.removeWhere((m) => m.markerId == const MarkerId('source'));
    _markers.removeWhere((m) => m.markerId == const MarkerId('destination'));
    sourceLocation = null;
    destinationLocation = null;
    notifyListeners();
  }

  void _updateCarMarker() {
    _markers.removeWhere((m) => m.markerId == const MarkerId('car'));
    if (_carLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('car'),
          position: _carLocation!,
          rotation: _carBearing,
          icon: _customCarIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ),
      );
    }
  }

  void _animateCameraToCar() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _carLocation!,
          zoom: 16,
          bearing: _carBearing,
        ),
      ),
    );
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * pi / 180;
    double lng1 = start.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lng2 = end.longitude * pi / 180;

    double dLng = lng2 - lng1;
    double y = sin(dLng) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    
    double bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }
}
