// services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bloom_and_shroom_spa/models.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<List<TemperatureData>> fetchLastMinuteData() async {
    final response = await http.get(Uri.parse('$baseUrl/data/last_minute'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TemperatureData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load last minute data');
    }
  }

  Future<List<TemperatureData>> fetchLastFiveMinutesData() async {
    final response = await http.get(Uri.parse('$baseUrl/data/last_five_minutes'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TemperatureData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load last five minutes data');
    }
  }

  Future<List<TemperatureData>> fetchLastHourData() async {
    final response = await http.get(Uri.parse('$baseUrl/data/last_hour'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TemperatureData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load last hour data');
    }
  }
}