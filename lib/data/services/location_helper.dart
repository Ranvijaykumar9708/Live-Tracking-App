import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationHelper {
  final String apiKey = 'AIzaSyBcVNOX83jHMMtpeH5Dk9rfUT6d6vGvVM0';

  Future<List<String>> fetchLocations(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json"
      "?input=$query&key=$apiKey&components=country:IN",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((place) => place['description'] as String)
              .toList();
        } else {
          throw Exception('Google API Error: ${data['status']}');
        }
      } else {
        throw Exception("Failed to fetch location data");
      }
    } catch (e) {
      print("LocationHelper Error: $e");
      return [];
    }
  }

  Future<Map<String, double>?> getCoordinates(String address) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {
            'lat': location['lat'],
            'lng': location['lng'],
          };
        }
      }
      return null;
    } catch (e) {
      print("Geocoding Error: $e");
      return null;
    }
  }
}
