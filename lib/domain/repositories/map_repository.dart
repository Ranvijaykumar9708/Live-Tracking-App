import 'package:google_maps_flutter/google_maps_flutter.dart';


abstract class MapRepository {
  Future<List<dynamic>> searchPlaces(String query);
  Future<LatLng?> getPlaceDetails(String placeId);
  Future<List<LatLng>> getRoutePolylines(LatLng origin, LatLng destination);
  Future<Map<String, dynamic>> getDistanceAndDuration(LatLng origin, LatLng destination);
}
