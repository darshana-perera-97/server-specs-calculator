import 'package:flutter/foundation.dart';
import '../models/server_metrics.dart';
import '../services/metrics_service.dart';

class MetricsProvider extends ChangeNotifier {
  final MetricsService _metricsService = MetricsService();
  
  ServerMetrics? _metrics;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  ServerMetrics? get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> fetchMetrics() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _metrics = await _metricsService.fetchMetrics();
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void startAutoRefresh() {
    // Auto-refresh every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (!_isLoading) {
        fetchMetrics();
      }
      startAutoRefresh();
    });
  }
}
