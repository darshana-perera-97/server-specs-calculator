import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/server_metrics.dart';

class MetricsService {
  static const String _baseUrl = 'http://69.197.187.24:3100';
  
  Future<ServerMetrics> fetchMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/metrics'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return ServerMetrics.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to load data');
        }
      } else {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading data: $e');
    }
  }
}

