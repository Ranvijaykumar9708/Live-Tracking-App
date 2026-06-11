import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import '../../domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final String _googleApiKey;

  MapRepositoryImpl(this._googleApiKey);

  @override
  Future<List<dynamic>> searchPlaces(String query) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body)['predictions'];
    } else {
      throw Exception('Failed to load predictions');
    }
  }

  @override
  Future<LatLng?> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final result = json.decode(response.body)['result'];
      final location = result['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
    return null;
  }

  @override
  Future<List<LatLng>> getRoutePolylines(LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if ((data['routes'] as List).isNotEmpty) {
        String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
        List<PointLatLng> result = PolylinePoints.decodePolyline(encodedPolyline);
        return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
      }
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getDistanceAndDuration(LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if ((data['routes'] as List).isNotEmpty) {
        final leg = data['routes'][0]['legs'][0];
        return {
          'distance': leg['distance']['text'],
          'duration': leg['duration']['text'],
          'distanceValue': leg['distance']['value'],
          'durationValue': leg['duration']['value'],
        };
      }
    }
    return {};
  }
}
